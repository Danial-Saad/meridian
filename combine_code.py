import os

output_file = 'meridian_full_code.txt'
folders_to_scan = ['lib']
files_to_include = ['pubspec.yaml']

with open(output_file, 'w', encoding='utf-8') as outfile:
    # دمج ملفات محددة مثل pubspec.yaml
    for file in files_to_include:
        if os.path.exists(file):
            outfile.write(f"--- File: {file} ---\n\n")
            with open(file, 'r', encoding='utf-8') as infile:
                outfile.write(infile.read() + "\n\n")
                
    # دمج جميع ملفات dart داخل مجلد lib
    for folder in folders_to_scan:
        for root, dirs, files in os.walk(folder):
            for file in files:
                if file.endswith('.dart'):
                    filepath = os.path.join(root, file)
                    outfile.write(f"--- File: {filepath} ---\n\n")
                    with open(filepath, 'r', encoding='utf-8') as infile:
                        outfile.write(infile.read() + "\n\n")

print(f"تم تجميع الأكواد بنجاح في ملف {output_file}")