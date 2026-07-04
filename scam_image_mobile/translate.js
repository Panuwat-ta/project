const fs = require('fs');
const path = require('path');

function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    isDirectory ? walkDir(dirPath, callback) : callback(path.join(dir, f));
  });
}

const translations = {};
let keyCounter = 1;

function generateKey(thaiStr) {
  for (const [k, v] of Object.entries(translations)) {
    if (v === thaiStr) return k;
  }
  const key = `auto_tr_${keyCounter++}`;
  translations[key] = thaiStr;
  return key;
}

const dartFiles = [];
walkDir('p:\\project\\scam_image_mobile\\lib', function(filePath) {
  if (filePath.endsWith('.dart') && !filePath.includes('app_translations.dart')) {
    dartFiles.push(filePath);
  }
});

let modifiedFiles = 0;

dartFiles.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  let originalContent = content;

  // Regex to find strings with Thai characters
  // Match single or double quotes, avoid escaping issues for simplicity
  const regex = /(['"])([^'"]*[\u0E00-\u0E7F]+[^'"]*)\1/g;
  
  let match;
  let replacements = [];
  
  // We need to loop and find all matches before mutating
  while ((match = regex.exec(content)) !== null) {
    // Check if it's already translated
    const afterMatch = content.slice(match.index + match[0].length, match.index + match[0].length + 12);
    if (afterMatch.includes('.tr(context)')) continue;
    // Skip if it is inside another .tr(context) like " 'th' " wait, th has no thai characters.

    replacements.push({
      start: match.index,
      end: match.index + match[0].length,
      fullMatch: match[0],
      quote: match[1],
      thaiStr: match[2]
    });
  }

  if (replacements.length > 0) {
    // Apply replacements from back to front to avoid offset shifting
    for (let i = replacements.length - 1; i >= 0; i--) {
      const rep = replacements[i];
      const key = generateKey(rep.thaiStr);
      const replacement = `'${key}'.tr(context)`;
      
      content = content.slice(0, rep.start) + replacement + content.slice(rep.end);
    }
    
    // Fix "const Text(" to "Text("
    content = content.replace(/const\s+Text\(/g, 'Text(');
    // Fix "const SnackBar(" to "SnackBar("
    content = content.replace(/const\s+SnackBar\(/g, 'SnackBar(');
    // Fix "const AlertDialog(" to "AlertDialog("
    content = content.replace(/const\s+AlertDialog\(/g, 'AlertDialog(');
    content = content.replace(/const\s+InputDecoration\(/g, 'InputDecoration(');
    content = content.replace(/const\s+Center\(/g, 'Center(');
    content = content.replace(/const\s+Scaffold\(/g, 'Scaffold(');
    content = content.replace(/const\s+Padding\(/g, 'Padding(');
    content = content.replace(/const\s+Column\(/g, 'Column(');
    content = content.replace(/const\s+Row\(/g, 'Row(');
    content = content.replace(/const\s+ListTile\(/g, 'ListTile(');
    content = content.replace(/const\s+AppBar\(/g, 'AppBar(');
    content = content.replace(/const\s+FloatingActionButton\(/g, 'FloatingActionButton(');

    // Add import if needed
    if (!content.includes('app_translations.dart')) {
      const importStr = "import 'package:scam_image_mobile/core/localization/app_translations.dart';\n";
      const firstImport = content.indexOf('import ');
      if (firstImport !== -1) {
        content = content.slice(0, firstImport) + importStr + content.slice(firstImport);
      } else {
        content = importStr + content;
      }
    }

    fs.writeFileSync(file, content, 'utf8');
    modifiedFiles++;
  }
});

fs.writeFileSync('p:\\project\\scam_image_mobile\\translations.json', JSON.stringify(translations, null, 2));
console.log(`Modified ${modifiedFiles} files. Extracted ${Object.keys(translations).length} strings.`);
