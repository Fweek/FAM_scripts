#THIS IS A DUMMY FILE AND NEEDS TO BE REPLACED WITH THE REAL CLASSIFY SCRIPT

import sys, os.path, shutil

os.chdir(sys.argv[1])

if not os.path.exists('Output-Classified'):
	os.makedirs('Output-Classified', )

src_files = os.listdir(str(sys.argv[1]+'/Output-Combined')
for file_name in src_files:
    full_file_name = os.path.join(str(sys.argv[1]+'/Output-Combined', file_name)
    if (os.path.isfile(full_file_name)):
        shutil.copy(full_file_name, str(sys.argv[1]+'/Output-Classified')
