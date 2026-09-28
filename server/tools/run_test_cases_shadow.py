#!/usr/bin/env python3
from __future__ import annotations
import sys
from pathlib import Path as _Path
sys.path.insert(0, str(_Path(__file__).resolve().parents[1]))
import csv, json, os, time
from collections import defaultdict
from pathlib import Path

import numpy as np
import onnxruntime as ort
from PIL import Image

from app.core.config import settings
from app.services.tiling import tile_inference, det_score_image

ROOT = Path('/home/panuwat/Pictures/Test-Cases')
OUT = Path(os.environ.get('TEST_CASES_OUT', '/home/panuwat/project/model/segformer/Det-Head/det_v1.0.6_det2b_mlp_source_balanced/test_cases_shadow_2026-09-28'))
MODEL_PATH = Path(os.environ.get('TEST_CASES_ONNX_MODEL', settings.ONNX_MODEL_PATH))
THRESH = 0.5


def rank_auc(y, s):
    y=np.asarray(y,dtype=int); s=np.asarray(s,dtype=float)
    pos=int(y.sum()); neg=len(y)-pos
    if not pos or not neg: return None
    order=np.argsort(s, kind='mergesort'); ranks=np.empty(len(s),float)
    i=0
    while i<len(s):
        j=i+1
        while j<len(s) and s[order[j]]==s[order[i]]: j+=1
        ranks[order[i:j]]=(i+1+j)/2.0
        i=j
    return float((ranks[y==1].sum()-pos*(pos+1)/2)/(pos*neg))


def avg_precision(y,s):
    y=np.asarray(y,dtype=int); s=np.asarray(s,dtype=float)
    pos=int(y.sum())
    if not pos: return None
    order=np.argsort(-s,kind='mergesort'); yy=y[order]
    tp=np.cumsum(yy); precision=tp/np.arange(1,len(yy)+1)
    return float(precision[yy==1].sum()/pos)


def cls_metrics(rows, score_key='det_score'):
    y=np.array([r['label'] for r in rows],int); s=np.array([r[score_key] for r in rows],float); p=(s>=THRESH).astype(int)
    tp=int(((p==1)&(y==1)).sum()); tn=int(((p==0)&(y==0)).sum()); fp=int(((p==1)&(y==0)).sum()); fn=int(((p==0)&(y==1)).sum())
    acc=(tp+tn)/len(y) if len(y) else None
    prec=tp/(tp+fp) if tp+fp else None; rec=tp/(tp+fn) if tp+fn else None; spec=tn/(tn+fp) if tn+fp else None
    f1=2*prec*rec/(prec+rec) if prec is not None and rec is not None and prec+rec else None
    return {'n':len(y),'authentic':int((y==0).sum()),'manipulated':int((y==1).sum()),'tp':tp,'tn':tn,'fp':fp,'fn':fn,'accuracy':acc,'precision':prec,'recall':rec,'specificity':spec,'f1':f1,'roc_auc':rank_auc(y,s),'average_precision':avg_precision(y,s)}


def pixel_metrics(c):
    tp,tn,fp,fn=[int(c[k]) for k in ('tp','tn','fp','fn')]
    i1=tp/(tp+fp+fn) if tp+fp+fn else None; i0=tn/(tn+fp+fn) if tn+fp+fn else None
    d1=2*tp/(2*tp+fp+fn) if 2*tp+fp+fn else None; d0=2*tn/(2*tn+fp+fn) if 2*tn+fp+fn else None
    vals_i=[x for x in (i0,i1) if x is not None]; vals_d=[x for x in (d0,d1) if x is not None]
    return {'tp':tp,'tn':tn,'fp':fp,'fn':fn,'pixel_accuracy':(tp+tn)/(tp+tn+fp+fn),'authentic_iou':i0,'forgery_iou':i1,'mIoU':sum(vals_i)/len(vals_i),'authentic_dice':d0,'forgery_dice':d1,'mDice':sum(vals_d)/len(vals_d)}


def build_items():
    items=[]
    for p in sorted((ROOT/'pairs'/'originals').glob('*')):
        if p.is_file(): items.append({'path':p,'label':0,'dataset':'pairs','source':'pairs_original'})
    for p in sorted((ROOT/'pairs'/'manipulated').glob('*')):
        if p.is_file(): items.append({'path':p,'label':1,'dataset':'pairs','source':'pairs_manipulated'})
    wm=ROOT/'with_mask'
    for dsdir in sorted(p for p in wm.iterdir() if p.is_dir()):
        for p in sorted((dsdir/'images'/'test').glob('*')):
            if not p.is_file(): continue
            mask=dsdir/'annotations'/'test'/p.name
            a=np.asarray(Image.open(mask)); label=int(np.any(a!=0))
            items.append({'path':p,'label':label,'dataset':dsdir.name,'source':'with_mask','mask':mask})
    return items


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    items=build_items(); print('items',len(items),flush=True)
    so=ort.SessionOptions(); so.log_severity_level=3
    sess=ort.InferenceSession(str(MODEL_PATH),sess_options=so,providers=[('CUDAExecutionProvider',{'gpu_mem_limit':512*1024*1024,'arena_extend_strategy':'kSameAsRequested'}),'CPUExecutionProvider'])
    input_name=sess.get_inputs()[0].name; providers=sess.get_providers(); print('providers',providers,flush=True)
    rows=[]; px=defaultdict(lambda: {'tp':0,'tn':0,'fp':0,'fn':0}); lat=[]; start=time.time()
    for idx,it in enumerate(items,1):
        t=time.time(); im=Image.open(it['path']).convert('RGB'); prob=tile_inference(sess,input_name,im,settings.ONNX_TILE_SIZE,settings.ONNX_TILE_OVERLAP,strict=True); det=float(det_score_image(sess,im,settings.ONNX_TILE_SIZE)); ms=(time.time()-t)*1000; lat.append(ms)
        ai=float(prob.max()); visual=int(round(ai*100)); seg_pred=int(ai>=THRESH); det_pred=int(det>=THRESH)
        row={'index':idx-1,'path':str(it['path']),'filename':it['path'].name,'dataset':it['dataset'],'source':it['source'],'label':it['label'],'width':im.width,'height':im.height,'ai_gen_probability':ai,'visual_score':visual,'seg_pred':seg_pred,'det_score':det,'det_pred':det_pred,'seg_det_agree':seg_pred==det_pred,'det_correct':det_pred==it['label'],'latency_ms':ms}
        if 'mask' in it:
            gt=np.asarray(Image.open(it['mask']))
            if gt.ndim==3: gt=np.any(gt!=0,axis=2)
            else: gt=gt!=0
            if gt.shape != prob.shape:
                gt=np.asarray(Image.fromarray(gt.astype(np.uint8)*255).resize((prob.shape[1],prob.shape[0]),Image.NEAREST))>0
            pred=prob>=THRESH
            c={'tp':int(np.logical_and(pred,gt).sum()),'tn':int(np.logical_and(~pred,~gt).sum()),'fp':int(np.logical_and(pred,~gt).sum()),'fn':int(np.logical_and(~pred,gt).sum())}
            for k,v in c.items(): px['overall'][k]+=v; px[it['dataset']][k]+=v
            row.update({f'pixel_{k}':v for k,v in c.items()})
        rows.append(row)
        if idx%10==0 or idx==len(items): print(f'{idx}/{len(items)} elapsed={time.time()-start:.1f}s last={it["dataset"]}/{it["path"].name} det={det:.3f} visual={visual}',flush=True)
    fields=sorted({k for r in rows for k in r})
    with (OUT/'predictions.csv').open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=fields); w.writeheader(); w.writerows(rows)
    groups={}; by=defaultdict(list)
    for r in rows: by[r['dataset']].append(r)
    for k,v in by.items(): groups[k]=cls_metrics(v)
    overall=cls_metrics(rows); seg_image=cls_metrics(rows,'ai_gen_probability')
    disagreement={'count':sum(not r['seg_det_agree'] for r in rows),'seg_high_det_low':sum(r['seg_pred']==1 and r['det_pred']==0 for r in rows),'seg_low_det_high':sum(r['seg_pred']==0 and r['det_pred']==1 for r in rows)}
    summary={'root':str(ROOT),'model':str(MODEL_PATH),'providers':providers,'threshold':THRESH,'samples':len(rows),'labels':{'authentic':sum(r['label']==0 for r in rows),'manipulated':sum(r['label']==1 for r in rows)},'det_head':overall,'seg_max_image_level':seg_image,'per_dataset_det':groups,'seg_localization':{k:pixel_metrics(v) for k,v in px.items()},'seg_det_disagreement':disagreement,'latency_ms':{'mean':float(np.mean(lat)),'p50':float(np.percentile(lat,50)),'p95':float(np.percentile(lat,95)),'max':float(np.max(lat))},'elapsed_sec':time.time()-start}
    (OUT/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
    lines=['# Test-Cases Shadow Evaluation','','- Input: `/home/panuwat/Pictures/Test-Cases`',f'- Samples: {len(rows)} ({summary["labels"]["authentic"]} authentic / {summary["labels"]["manipulated"]} manipulated)',f'- ONNX: `{MODEL_PATH}`',f'- Providers: {providers}',f'- Threshold: {THRESH}','','## Det Head image-level','',f'- Accuracy: {overall["accuracy"]:.4f}',f'- Precision: {overall["precision"]:.4f}',f'- Recall: {overall["recall"]:.4f}',f'- Specificity: {overall["specificity"]:.4f}',f'- F1: {overall["f1"]:.4f}',f'- ROC-AUC: {overall["roc_auc"]:.4f}',f'- AP: {overall["average_precision"]:.4f}',f'- TP/TN/FP/FN: {overall["tp"]}/{overall["tn"]}/{overall["fp"]}/{overall["fn"]}','','## Seg-vs-Det disagreement','',json.dumps(disagreement,ensure_ascii=False),'','## SegFormer localization (with_mask 105)','']
    loc=summary['seg_localization']['overall']; lines += [f'- mIoU: {loc["mIoU"]:.4f}',f'- mDice: {loc["mDice"]:.4f}',f'- Forgery IoU: {loc["forgery_iou"]:.4f}',f'- Forgery Dice: {loc["forgery_dice"]:.4f}',f'- Pixel Accuracy: {loc["pixel_accuracy"]:.4f}','','## Per dataset Det accuracy','']
    for k in sorted(groups): lines.append(f'- {k}: {groups[k]["accuracy"]:.4f} (n={groups[k]["n"]})')
    lines += ['','## Runtime','',f'- Mean: {summary["latency_ms"]["mean"]:.1f} ms/image',f'- P50: {summary["latency_ms"]["p50"]:.1f} ms',f'- P95: {summary["latency_ms"]["p95"]:.1f} ms',f'- Total: {summary["elapsed_sec"]:.1f} s','', '> This is pre-production test data and is not appended to the real-user shadow telemetry log.']
    (OUT/'REPORT.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print('DONE',OUT,flush=True); print(json.dumps(summary,ensure_ascii=False,indent=2),flush=True)

if __name__=='__main__': main()
