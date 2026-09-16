import os
import re

WIKI_DIR = '/home/panuwat/project/wiki'

replacements = [
    # Concepts file renaming links
    (r'concepts/ela-technique', r'concepts/semantic-segmentation'),
    (r'ela-technique\|ELA', r'semantic-segmentation|Semantic Segmentation'),
    
    # Specific ELA phrasing
    (r'ELA \(Error Level Analysis\)', r'Semantic Segmentation'),
    (r'Error Level Analysis \(ELA\)', r'Semantic Segmentation'),
    (r'Error Level Analysis', r'Semantic Segmentation'),
    (r'\(ELA\)', r'(Semantic Segmentation)'),
    (r'ELA \+ SegFormer', r'SegFormer'),
    (r'SegFormer \+ ELA', r'SegFormer'),
    (r'\bELA\b', r'Semantic Segmentation'),
    
    # Grad-CAM phrasing
    (r'Grad-CAM Heatmap', r'Heatmap'),
    (r'Grad-CAM', r'Heatmap'),
    
    # Specific outdated model terms
    (r'PSCC-Net', r'SegFormer'),
    (r'Freeze Backbone', r'Differential Learning Rates'),
    (r'Redux', r'BLoC'),
    
    # Metrics
    (r'Pixel Accuracy', r'mIoU'),
    (r'F1-Score', r'mDice')
]

for root, dirs, files in os.walk(WIKI_DIR):
    if '.obsidian' in root or 'scratch' in root:
        continue
    for file in files:
        if not file.endswith('.md'):
            continue
            
        path = os.path.join(root, file)
        
        # Don't touch the file we are rewriting manually
        if file == 'ela-technique.md' or file == 'semantic-segmentation.md':
            continue
            
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        new_content = content
        for pattern, replacement in replacements:
            new_content = re.sub(pattern, replacement, new_content, flags=re.IGNORECASE)
            
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Updated {os.path.relpath(path, WIKI_DIR)}')
