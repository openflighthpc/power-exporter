#!/bin/bash

INSTALL_DEST=/opt/power-exporter

cp -R ./power-exporter /opt/power-exporter
cp ./power-exporter.service /usr/lib/systemd/system/power-exporter.service 
