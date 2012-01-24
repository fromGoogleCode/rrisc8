# Hey Emacs, this is a -*- makefile -*-
# Makefile for hex2mif.c
# Author: WangMengyin 2012-12-24
# Ver 1.0.0

SOURCE = hex2mif.c
EXE = hex2mif.exe
CC = gcc
CFLAGS = -Os -Wall -w
REMOVE = rm -f
MOVE = mv -f

all:
	$(CC) $(CFLAGS) -o $(EXE) $(SOURCE)
	$(MOVE) $(EXE) ../$(EXE)

clean:
	$(REMOVE) ../$(EXE)
	
rebuild: clean all



