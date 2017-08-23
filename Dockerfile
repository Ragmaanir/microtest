FROM alpine:3.6

RUN apk add --no-cache \
            xvfb \
            # Additionnal dependencies for better rendering
            ttf-freefont \
            fontconfig \
            dbus \
    && \

    # Install wkhtmltopdf from `testing` repository
    apk add qt5-qtbase-dev \
            wkhtmltopdf \
            --no-cache \
            --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
            --allow-untrusted
RUN \
    # Wrapper for xvfb
    mv /usr/bin/wkhtmltoimage /usr/bin/wkhtmltoimage-origin && \
    echo $'#!/usr/bin/env sh\n\
Xvfb :0 -screen 0 1024x768x24 -ac +extension GLX +render -noreset & \n\
DISPLAY=:0.0 wkhtmltoimage-origin $@ \n\
killall Xvfb\
' > /usr/bin/wkhtmltoimage && \
chmod +x /usr/bin/wkhtmltoimage

RUN chmod +x /usr/bin/wkhtmltoimage

RUN apk add --no-cache exiftool

WORKDIR /root
