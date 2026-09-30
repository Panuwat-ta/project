from __future__ import annotations
import csv, json, os
from pathlib import Path
import numpy as np
import torch
from PIL import Image

from det_head import build_seg_model, pool_stage_features

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CONFIG=str(PROJECT_ROOT/'configs/segformer_mit-b2-v11.py')
CKPT=str(PROJECT_ROOT/'work_dirs/v1.0.6/best_mIoU_iter_195000.pth')
CACHE='/home/panuwat/Pictures/Det-Head/features/v1.0.6-det2-clean'
CSV='/home/panuwat/Pictures/Det-Head/manifests/det-train-v2-clean.csv'
OUT=PROJECT_ROOT/'Det-Head/det_v1.0.6_det2b_mlp_source_balanced/real_pilot_11_2026-09-29/feature_neighbor_analysis'
OUT.mkdir(parents=True,exist_ok=True)

CASES={
 'Original1':'/home/panuwat/project/server/uploads/59570fd99fbaed7efb0403cb67257e7c5cfc947f4fbc08581b181cbed2e6c3f8.png',
 'Original3':'/home/panuwat/project/server/uploads/6cfc06e8cbda637726d282b0e8916f0920694514c02622857f131cbbe5623423.png',
 'Original7':'/home/panuwat/project/server/uploads/7d8eaad635015eaae4e5b344fea40ea51d31640a420672c2d6aa911e3067bae3.png',
 'Manipulated1':'/home/panuwat/project/server/uploads/81fd035e6bc71afbda1c3749c53dadfb01c590cf331199d6a763c031e9cebaca.png',
 'Manipulated2':'/home/panuwat/project/server/uploads/6126995e80c32ff10c3a6d2bd9f7412751a93c0c117d9dfc28fe509dad77514f.png',
}
GT={'Original1':0,'Original3':0,'Original7':0,'Manipulated1':1,'Manipulated2':1}
MEAN=np.array([123.675,116.28,103.53],dtype=np.float32).reshape(1,1,3)
STD=np.array([58.395,57.12,57.375],dtype=np.float32).reshape(1,1,3)


def image_tensor(path):
    im=Image.open(path).convert('RGB').resize((512,512),Image.BILINEAR)
    arr=np.asarray(im,dtype=np.float32)
    arr=(arr-MEAN)/STD
    return torch.from_numpy(arr.transpose(2,0,1)).unsqueeze(0)


def extract(model,path):
    with torch.inference_mode():
        feats=model.extract_feat(image_tensor(path))
        return pool_stage_features(feats).squeeze(0).cpu().numpy().astype(np.float32)


def top_neighbors(X, q, k=50, chunk=4096):
    q=q/(np.linalg.norm(q)+1e-12)
    best=[]
    for st in range(0,len(X),chunk):
        a=np.asarray(X[st:st+chunk],dtype=np.float32)
        norms=np.linalg.norm(a,axis=1)+1e-12
        sim=(a@q)/norms
        take=min(k,len(sim))
        idx=np.argpartition(sim,-take)[-take:]
        best.extend((float(sim[i]),st+int(i)) for i in idx)
        best=sorted(best,reverse=True)[:k]
    return best
def main():
    rows=list(csv.DictReader(open(CSV)))
    X=np.load(f'{CACHE}/train/features.npy',mmap_mode='r')
    y=np.load(f'{CACHE}/train/labels.npy',mmap_mode='r').reshape(-1).astype(int)
    model=build_seg_model(CONFIG,CKPT,'cpu').eval()
    result={}
    detail=[]
    for name,path in CASES.items():
        print('extract',name,flush=True)
        q=extract(model,path)
        neigh=top_neighbors(X,q,k=50)
        idx=np.array([i for _,i in neigh],dtype=int)
        labs=y[idx]
        entry={
            'ground_truth':GT[name],
            'path':path,
            'top10_manipulated_fraction':float(y[idx[:10]].mean()),
            'top20_manipulated_fraction':float(y[idx[:20]].mean()),
            'top50_manipulated_fraction':float(labs.mean()),
            'top1_similarity':float(neigh[0][0]),
            'mean_top10_similarity':float(np.mean([s for s,_ in neigh[:10]])),
        }
        result[name]=entry
        print(name,json.dumps(entry),flush=True)
        for rank,(sim,i) in enumerate(neigh[:20],1):
            r=rows[i]
            detail.append({'query':name,'rank':rank,'similarity':sim,'neighbor_index':i,
                           'label':int(r['label']),'dataset':r.get('dataset',''),
                           'source':r.get('source',''),'path':r['path']})
    with (OUT/'neighbors_top20.csv').open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(detail[0])); w.writeheader(); w.writerows(detail)
    (OUT/'summary.json').write_text(json.dumps(result,indent=2))
    print('saved',OUT)


if __name__=='__main__':
    main()
