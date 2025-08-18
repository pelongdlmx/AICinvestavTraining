pip install --break-system-packages -r ./requirements.txt
apt-get update
apt-get install  libgl1
python3 -m spacy download en_core_web_sm --break-system-packages