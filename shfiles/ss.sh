maim -s | magick - \
    -gamma 0.6 \
    -modulate 115,100,100 \
    png:- | xclip -selection clipboard -t image/png
