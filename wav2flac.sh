for i in *.wav
do
    sox "$i" "$(basename -s .wav "$i").flac"
done
