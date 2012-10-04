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

class Command {
    String name;
    String usage;
    String description;
    int minLevel;
    bool subCommand;

    int minArgc;
    int maxArgc;

    Command(String &newUsage, String &newDescription, int newMinLevel,
            bool newSubCommand) {
        set(newUsage, newDescription, newMinLevel, newSubCommand);
    }

    void set(String &newUsage, String &newDescription, int newMinLevel,
            bool newSubCommand) {
        name = "";
        usage = newUsage;
        description = newDescription;
        minLevel = newMinLevel;
        subCommand = newSubCommand;

        analyzeUsage();

        if (!subCommand)
            G_RegisterCommand(name);
    }

    /*
     * NOTE: assumes no nesting.
     */
    void analyzeUsage() {
        String newUsage = "";
        minArgc = 0;
        maxArgc = 0;
        int dots = 0;
        bool naming = true;
        for (uint i = 0; i < usage.len(); i++) {
            String c = usage.substr(i, 1);
            if (naming) {
                if (c == " ")
                    naming = false;
                else
                    name += c;
            } else {
                if (c == "<") {
                    minArgc++;
                    if (maxArgc != INFINITY)
                        maxArgc++;
                } else if (c == "[") {
                    if (maxArgc != INFINITY)
                        maxArgc++;
                }

                if (c == ".") {
                    dots++;
                    if (dots == 3)
                        maxArgc = INFINITY;
                } else {
                    for (int i = 0; i < dots; i++)
                        newUsage += ".";
                    newUsage += c;
                    dots = 0;
                }
            }
        }
        usage = newUsage;
    }

    bool validUsage(int argc) {
        return argc >= minArgc && (argc <= maxArgc || maxArgc == INFINITY);
    }

    void say(String &msg) {
        notify(highlight(name) + ": " + msg);
    }
}
