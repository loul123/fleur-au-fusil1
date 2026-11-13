#!/usr/bin/env python3
"""Construit LaFleurAuFusil.rbxlx : une place Roblox prête à ouvrir dans Studio,
avec tous les scripts de src/ rangés comme dans default.project.json.

Usage : python3 tools/build_place.py   (depuis la racine du dépôt)
"""
import os
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "LaFleurAuFusil.rbxlx")
_ref = [0]


def ref():
    _ref[0] += 1
    return "RBX%08X" % _ref[0]


def cdata(text):
    # "]]>" est interdit dans un bloc CDATA : on le coupe en deux blocs
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def item(cls, name, children=(), source=None, extra=""):
    props = '<string name="Name">%s</string>' % escape(name)
    if source is not None:
        props += '<ProtectedString name="Source">%s</ProtectedString>' % cdata(source)
    props += extra
    return '<Item class="%s" referent="%s"><Properties>%s</Properties>%s</Item>' % (
        cls, ref(), props, "".join(children))


def from_dir(path):
    """Fichiers .lua -> ModuleScript, .server.lua -> Script, .client.lua -> LocalScript, dossiers -> Folder."""
    children = []
    for entry in sorted(os.listdir(path)):
        full = os.path.join(path, entry)
        if os.path.isdir(full):
            children.append(item("Folder", entry, from_dir(full)))
            continue
        if not entry.endswith(".lua"):
            continue
        with open(full, encoding="utf-8") as f:
            src = f.read()
        if entry.endswith(".server.lua"):
            children.append(item("Script", entry[:-len(".server.lua")], source=src))
        elif entry.endswith(".client.lua"):
            children.append(item("LocalScript", entry[:-len(".client.lua")], source=src))
        else:
            children.append(item("ModuleScript", entry[:-len(".lua")], source=src))
    return children


def main():
    src = os.path.join(ROOT, "src")
    services = [
        item("ReplicatedStorage", "ReplicatedStorage", [item("Folder", "FleurShared", from_dir(os.path.join(src, "shared")))]),
        item("ServerScriptService", "ServerScriptService", [item("Folder", "FleurServer", from_dir(os.path.join(src, "server")))]),
        item("StarterPlayer", "StarterPlayer", [
            item("StarterPlayerScripts", "StarterPlayerScripts", [item("Folder", "FleurClient", from_dir(os.path.join(src, "client")))]),
            item("StarterCharacterScripts", "StarterCharacterScripts"),
        ], extra='<token name="GameSettingsAvatar">1</token>'),  # avatars R15
        item("Teams", "Teams"),
    ]
    xml = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
           'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
           '<External>null</External><External>nil</External>'
           + "".join(services) + "</roblox>\n")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(xml)
    print("Place écrite :", OUT, "(%d scripts)" % xml.count("ProtectedString name=\"Source\""))


if __name__ == "__main__":
    main()
