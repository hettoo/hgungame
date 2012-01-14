/*
Copyright (C) 2012 hettoo

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

class Command {
    cString name;
    cString usage;
    cString description;
    int min_rank;

    int min_argc;
    int max_argc;

    Command(cString &new_usage, cString &new_description, int new_min_rank) {
        set(new_usage, new_description, new_min_rank);
    }

    void set(cString &new_usage, cString &new_description, int new_min_rank) {
        name = "";
        usage = new_usage;
        description = new_description;
        min_rank = new_min_rank;

        analyze_usage();
    }

    /*
     * NOTE: assumes no nesting.
     */
    void analyze_usage() {
        cString new_usage = "";
        min_argc = 0;
        max_argc = 0;
        int dots = 0;
        bool naming = true;
        for (int i = 0; i < usage.len(); i++) {
            cString c = usage.substr(i, 1);
            if (naming) {
                if (c == " ")
                    naming = false;
                else
                    name += c;
            } else {
                if (c == "<") {
                    min_argc++;
                    if (max_argc != INFINITY)
                        max_argc++;
                } else if (c == "[") {
                    if (max_argc != INFINITY)
                        max_argc++;
                }

                if (c == ".") {
                    dots++;
                    if (dots == 3)
                        max_argc = INFINITY;
                } else {
                    for (int i = 0; i < dots; i++)
                        new_usage += ".";
                    new_usage += c;
                    dots = 0;
                }
            }
        }
        usage = new_usage;
    }

    bool valid_usage(int argc) {
        return argc >= min_argc && (argc <= max_argc || max_argc == INFINITY);
    }

    void say(cString &msg) {
        notify(highlight(name) + ": " + msg);
    }
}
