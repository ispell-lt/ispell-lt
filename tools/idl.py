#!/usr/bin/env python2.3
# -*- coding: iso-8859-13 -*-

import sys
from Tkinter import Tk
from idlelib.PyShell import PyShell, PyShellFileList
import idlelib.PyShell

def main():
    idlelib.PyShell.use_subprocess = False

    root = Tk(className="Idle")
    root.withdraw()
    flist = PyShellFileList(root)
    shell = flist.pyshell = PyShell(flist)
    shell.shell_title = "Ispell-LT"

    sys.argv = sys.argv[1:]

    shell.interp.execfile(sys.argv[0])
    #shell.interp.execsource("raw_input('Paspauskite Enter...')")

    root.destroy()


if __name__ == '__main__':
    main()
