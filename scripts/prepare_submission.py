"""Tạo báo cáo Word và gói source từ kết quả kiểm thử trong workspace."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from xml.sax.saxutils import escape
import json
import re
import struct
import os

root = Path(__file__).resolve().parents[1]
out = root / 'submission'
out.mkdir(exist_ok=True)
if (out / 'users-web.json').exists():
    records = json.loads((out / 'users-web.json').read_text())
    assert all(set(row) == {'email', 'matkhau', 'hoten', 'hinhanh'} for row in records)
    (out / 'users.json').write_text(json.dumps(records, ensure_ascii=False, indent=2) + '\n')

paragraphs = []
rels = ['<Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>']
images = []
def paragraph(text, style='Normal'):
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'\1 (\2)', text).replace('**', '').replace('`', '')
    paragraphs.append(f'<w:p><w:pPr><w:pStyle w:val="{style}"/></w:pPr><w:r><w:t xml:space="preserve">{escape(text)}</w:t></w:r></w:p>')

paragraph('BÁO CÁO GIỮA KỲ', 'Title')
paragraph('Ứng dụng quản lý người dùng ECOMER', 'Title')
paragraph('Môn: Lập trình đa nền tảng')
paragraph('Sinh viên: ......................................    Lớp: ......................................')
paragraph('Bản hướng dẫn và kết quả kiểm chứng trong workspace. Hoàn thiện thông tin sinh viên và liên kết nộp bài trước khi nộp.')
for filename in ['docs/BAO_CAO_HUONG_DAN.md', 'docs/KIEM_THU.md']:
    path = root / filename
    if not path.exists():
        continue
    for line in path.read_text().splitlines():
        if line.startswith('```') or re.fullmatch(r'[| :\-]+', line or 'x'):
            continue
        if line.startswith('# '): paragraph(line[2:], 'Heading1')
        elif line.startswith('## '): paragraph(line[3:], 'Heading2')
        elif line.strip(): paragraph(line)
paragraph('Phụ lục: ảnh chụp thực tế trên trình duyệt', 'Heading1')
for index, path in enumerate(sorted((out / 'screenshots').glob('[0-9][0-9]-*.png')), 1):
    data = path.read_bytes()
    width, height = struct.unpack('>II', data[16:24])
    cx = min(5486400, round(width * 9525))
    cy = round(cx * height / width)
    if cy > 6500000:
        cx = round(cx * 6500000 / cy)
        cy = 6500000
    name = f'image{index}.png'
    rel = f'rIdImage{index}'
    rels.append(f'<Relationship Id="{rel}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/{name}"/>')
    images.append((name, data))
    paragraph(path.stem.replace('-', ' '), 'Heading2')
    if 'mobile-web' in path.stem:
        paragraph('Ảnh này là giao diện web ở kích thước mobile; không thay thế minh chứng chạy Android.')
    paragraphs.append(f'''<w:p><w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0"><wp:extent cx="{cx}" cy="{cy}"/><wp:docPr id="{index}" name="{name}"/><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic><pic:nvPicPr><pic:cNvPr id="{index}" name="{name}"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="{rel}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="{cx}" cy="{cy}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>''')
ns = 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"'
xml = f'<?xml version="1.0" encoding="UTF-8"?><w:document {ns}><w:body>' + ''.join(paragraphs) + '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/></w:sectPr></w:body></w:document>'
styles = '''<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:sz w:val="22"/></w:rPr></w:rPrDefault></w:docDefaults><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:pPr><w:spacing w:after="120" w:line="276" w:lineRule="auto"/></w:pPr></w:style>'''
for name, size in [('Title', 36), ('Heading1', 30), ('Heading2', 26)]:
    styles += f'<w:style w:type="paragraph" w:styleId="{name}"><w:name w:val="{name}"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/><w:spacing w:before="240" w:after="120"/></w:pPr><w:rPr><w:b/><w:color w:val="2563EB"/><w:sz w:val="{size}"/></w:rPr></w:style>'
styles += '</w:styles>'
with ZipFile(out / 'BAO_CAO_ECOMER.docx', 'w', ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/></Types>')
    z.writestr('_rels/.rels', '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>')
    z.writestr('word/document.xml', xml)
    z.writestr('word/styles.xml', styles)
    z.writestr('word/_rels/document.xml.rels', '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + ''.join(rels) + '</Relationships>')
    for name, data in images: z.writestr('word/media/' + name, data)
folders = ['lib', 'assets', 'android', 'web', 'test', 'integration_test', 'test_driver', 'functions', 'config', 'docs', 'scripts', 'firebase']
exclude = {'node_modules', 'build', '.gradle', '.dart_tool', '.idea', '.cxx'}
with ZipFile(out / 'ecomer-source.zip', 'w', ZIP_DEFLATED) as z:
    for folder in folders:
        for current, directories, filenames in os.walk(root / folder):
            directories[:] = [name for name in directories if name not in exclude]
            for filename in filenames:
                path = Path(current) / filename
                if filename == 'local.properties' or filename == 'production.json' or filename.endswith(('.log', '.keystore', '.jks')): continue
                z.write(path, 'ecomer/' + str(path.relative_to(root)))
    for name in ['README.md', 'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'firebase.json', 'firebase.rules-test.json', 'firestore.rules', 'firestore.indexes.json', 'package.json', 'package-lock.json', '.gitignore', '.metadata', 'submission/README.md', 'submission/users.json']:
        if (root / name).exists(): z.write(root / name, 'ecomer/' + name)
print('Đã tạo BAO_CAO_ECOMER.docx và ecomer-source.zip; không chứa build, node_modules hay cấu hình production.')
