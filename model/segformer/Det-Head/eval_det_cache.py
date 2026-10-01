"""Evaluate a Det Head checkpoint on cached pooled SegFormer features."""
import argparse, csv, json, os
from collections import defaultdict
import numpy as np
import torch
from det_head import load_det


def roc_auc_ap(y, score):
    y=np.asarray(y).astype(int); score=np.asarray(score)
    pos=int((y==1).sum()); neg=int((y==0).sum())
    if pos==0 or neg==0:
        return None, None
    order=np.argsort(-score, kind='mergesort')
    ys=y[order]
    tp=np.cumsum(ys==1); fp=np.cumsum(ys==0)
    tpr=np.r_[0.0, tp/pos, 1.0]; fpr=np.r_[0.0, fp/neg, 1.0]
    auc=float(np.trapz(tpr, fpr))
    prec=tp/np.arange(1,len(ys)+1)
    ap=float(prec[ys==1].mean())
    return auc, ap


def metrics(y, pred, score):
    y=np.asarray(y); pred=np.asarray(pred); score=np.asarray(score)
    tp=int(((y==1)&(pred==1)).sum()); tn=int(((y==0)&(pred==0)).sum())
    fp=int(((y==0)&(pred==1)).sum()); fn=int(((y==1)&(pred==0)).sum())
    n=len(y)
    precision=tp/(tp+fp) if tp+fp else None
    recall=tp/(tp+fn) if tp+fn else None
    specificity=tn/(tn+fp) if tn+fp else None
    f1=(2*precision*recall/(precision+recall)
        if precision is not None and recall is not None and precision+recall else None)
    auc, ap = roc_auc_ap(y, score)
    return {'n':n,'tp':tp,'tn':tn,'fp':fp,'fn':fn,
            'accuracy':(tp+tn)/n if n else None,'precision':precision,
            'recall':recall,'specificity':specificity,'f1':f1,
            'roc_auc':auc,'average_precision':ap,
            'mean_score':float(score.mean()) if n else None}


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--checkpoint',required=True)
    ap.add_argument('--feature-cache',required=True)
    ap.add_argument('--split',default='val')
    ap.add_argument('--csv',default=None)
    ap.add_argument('--threshold',type=float,default=0.5)
    ap.add_argument('--out-dir',default=None)
    args=ap.parse_args()
    meta=json.load(open(os.path.join(args.feature_cache,'metadata.json')))
    if args.csv is None:
        args.csv=next(x['csv'] for x in meta['splits'] if x['split']==args.split)
    rows=list(csv.DictReader(open(args.csv)))
    d=os.path.join(args.feature_cache,args.split)
    X=np.load(os.path.join(d,'features.npy'),mmap_mode='r')
    y=np.load(os.path.join(d,'labels.npy'),mmap_mode='r').reshape(-1).astype(int)
    if len(rows)!=len(X): raise ValueError('CSV/cache length mismatch')
    model=load_det(args.checkpoint,'cpu').eval()
    ss=[]
    with torch.no_grad():
        for i in range(0,len(X),4096):
            x=torch.from_numpy(np.asarray(X[i:i+4096]).copy()).float()
            ss.append(torch.sigmoid(model.forward_pooled(x)).reshape(-1).numpy())
    score=np.concatenate(ss); pred=(score>=args.threshold).astype(int)
    by=defaultdict(list)
    for i,r in enumerate(rows): by[r.get('dataset','unknown')].append(i)
    result={'threshold':args.threshold,'overall':metrics(y,pred,score),'by_dataset':{}}
    for k,idx in sorted(by.items()):
        a=np.asarray(idx); result['by_dataset'][k]=metrics(y[a],pred[a],score[a])
    accs=[x['accuracy'] for x in result['by_dataset'].values() if x['accuracy'] is not None]
    result['macro_dataset_accuracy']=float(np.mean(accs))
    print('OVERALL',json.dumps(result['overall']))
    print('MACRO_DATASET_ACC',result['macro_dataset_accuracy'])
    for k,v in result['by_dataset'].items(): print('DATASET',k,json.dumps(v))
    if args.out_dir:
        os.makedirs(args.out_dir,exist_ok=True)
        json.dump(result,open(os.path.join(args.out_dir,f'{args.split}_metrics.json'),'w'),indent=2)
    return result

if __name__=='__main__': main()
