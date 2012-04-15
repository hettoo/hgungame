/*
Copyright (C) 2012 Gerco van Heerdt

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

class IPC {
    cString dir;
    cString deadfile;
    int next;

    IPC(cString &dir) {
        init(dir);
    }

    IPC() {
        init("ipc");
    }

    void init(cString &dir) {
        this.dir = dir;
        if (this.dir.len() > 0 && this.dir.substr(this.dir.len() - 1, 1) != "/")
            this.dir += "/";
        deadfile = "dead";
        G_WriteFile(filename(deadfile, true), "1");
    }

    cString @filename(cString file, bool external) {
        return dir + (external ? "external" : "internal") + "/" + file;
    }

    cString @filename(int id, bool external) {
        return filename(id + "", external);
    }

    bool fileExists(cString file, bool external) {
        return G_FileLength(filename(file, external)) > 0;
    }

    bool fileExists(int id, bool external) {
        return fileExists(id + "", external);
    }

    bool alive() {
        return !fileExists(deadfile, true);
    }

    int issue(cString &command) {
        int id = next++;
        G_WriteFile(filename(id, false), command);
        return id;
    }

    bool processing(int id) {
        return !fileExists(id, false);
    }

    bool hasAnswer(int id) {
        return fileExists(id, true);
    }

    cString @get(int id) {
        if (!hasAnswer(id))
            return "";

        cString filename = filename(id, true);
        cString result = G_LoadFile(filename);
        discard(id);
        return result;
    }

    cString @wait(int id) {
        while (!hasAnswer(id))
            continue;

        return get(id);
    }

    cString @wait(cString &command) {
        return wait(issue(command));
    }

    void discard(int id) {
        G_WriteFile(filename(id, false), "");
    }
}
