# syntax=docker/dockerfile:1
FROM windroseserver/windroseserver@sha256:2ccfe3319d0b4f9637ba08dbefb44f8c64c97309ba1b5e4c152e418ef63755d7 AS publisher

FROM scratch AS tools
ADD cpython-3.12.16-linux-amd64.tar.gz /opt/windrose-runtime/
COPY --chmod=0444 native_first_run.py patch_native_world_backup.py /opt/windrose-first-run/

# Copy the publisher filesystem without its inherited VOLUME declaration.
FROM scratch AS server
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
COPY --from=publisher / /
COPY --from=tools /opt/ /opt/
COPY --chmod=0555 windrose-game /usr/local/bin/windrose-pelican
COPY --chmod=0555 windrose-adapter /usr/local/bin/windrose-adapter
RUN ["/bin/sh", "-euxc", "chmod 0755 /home/ue_user; root=/home/ue_user/app/R5; test -x \"$root/Binaries/Linux/WindroseServer-Linux-Shipping\"; if [ -d \"$root/Saved\" ]; then rmdir \"$root/Saved\"; fi; rm -f \"$root/ServerDescription.json\"; ln -s /home/container/R5/Saved \"$root/Saved\"; ln -s /home/container/R5/ServerDescription.json \"$root/ServerDescription.json\"; test ! -e /var/tmp/R5; ln -s /home/container/.windrose-backup-tmp /var/tmp/R5; mkdir -p /home/container"]
WORKDIR /home/container
USER 99:100
RUN ["/opt/windrose-runtime/python/bin/python3.12", "-E", "-B", "-c", "import fcntl, hashlib, zipfile, zlib; assert hasattr(hashlib, 'file_digest')"]
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/local/bin/windrose-adapter"]
