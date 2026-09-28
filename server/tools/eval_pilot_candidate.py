from __future__ import annotations
import sys
from pathlib import Path as _Path
sys.path.insert(0, str(_Path(__file__).resolve().parents[1]))
import argparse, csv, json, time
from pathlib import Path
import numpy as np
import onnxruntime as ort
from PIL import Image

from app.core.config import settings
from app.services.tiling import tile_inference, det_score_image


def metrics(rows):
    y=np.array([int(r['label']) for r in rows]); p=np.array([int(r['det_pred']) for r in rows])
    tp=int(((p==1)&(y==1)).sum()); tn=int(((p==0)&(y==0)).sum())
    fp=int(((p==1)&(y==0)).sum()); fn=int(((p==0)&(y==1)).sum())
    precision=tp/(tp+fp) if tp+fp else 0.0
    recall=tp/(tp+fn) if tp+fn else 0.0
    specificity=tn/(tn+fp) if tn+fp else 0.0
    f1=2*precision*recall/(precision+recall) if precision+recall else 0.0
    return {'n':len(rows),'tp':tp,'tn':tn,'fp':fp,'fn':fn,
            'accuracy':(tp+tn)/len(rows),'precision':precision,'recall':recall,
            'specificity':specificity,'f1':f1}


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--model', required=True)
    ap.add_argument('--baseline-csv', required=True)
    ap.add_argument('--uploads', default='/home/panuwat/project/server/uploads')
    ap.add_argument('--out-dir', required=True)
    args=ap.parse_args()
    out=Path(args.out_dir); out.mkdir(parents=True,exist_ok=True)
    base=list(csv.DictReader(open(args.baseline_csv)))
    so=ort.SessionOptions(); so.log_severity_level=3
    sess=ort.InferenceSession(args.model,sess_options=so,
        providers=[('CUDAExecutionProvider',{'gpu_mem_limit':512*1024*1024,
                   'arena_extend_strategy':'kSameAsRequested'}),'CPUExecutionProvider'])
    input_name=sess.get_inputs()[0].name
    rows=[]
    for b in base:
        prefix=b['image_hash_prefix']; matches=list(Path(args.uploads).glob(prefix+'*'))
        if len(matches)!=1:
            raise RuntimeError(f'{b["title"]}: expected 1 upload for {prefix}, got {len(matches)}')
        path=matches[0]; im=Image.open(path).convert('RGB'); t=time.time()
        prob=tile_inference(sess,input_name,im,settings.ONNX_TILE_SIZE,
                            settings.ONNX_TILE_OVERLAP,strict=True)
        det=float(det_score_image(sess,im,settings.ONNX_TILE_SIZE)); ms=(time.time()-t)*1000
        ai=float(prob.max()); pred=int(det>=0.5); label=int(b['label'])
        rows.append({'title':b['title'],'label':label,'path':str(path),
                     'det2b_score':float(b['det_score']),'det_score':det,
                     'det_delta':det-float(b['det_score']),'det_pred':pred,
                     'det_correct':int(pred==label),'ai_gen_probability':ai,
                     'visual_score':int(round(ai*100)),'latency_ms':ms})
    with (out/'predictions.csv').open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
    summary={'model':args.model,'providers':sess.get_providers(),'metrics':metrics(rows),
             'scores':{r['title']:{'det2b':r['det2b_score'],'candidate':r['det_score'],
                                   'delta':r['det_delta']} for r in rows}}
    (out/'summary.json').write_text(json.dumps(summary,indent=2))
    print(json.dumps(summary,indent=2))
    print('PER_IMAGE')
    for r in rows:
        status='OK' if r['det_correct'] else 'WRONG'
        print(f"{r['title']:12s} gt={r['label']} det2b={r['det2b_score']:.4f} "
              f"candidate={r['det_score']:.4f} delta={r['det_delta']:+.4f} "
              f"pred={r['det_pred']} {status} visual={r['visual_score']}")


if __name__=='__main__':
    main()
