import pcbnew, re
b = pcbnew.LoadBoard(r'C:\Users\Timm\AppData\Local\Temp\codex-file-preview-jgaFmu\CamperPilot Core.kicad_pcb')
s = open('pcb-width-schematic.net', encoding='utf-8').read()
mism = []
for block in s.split('\n\t\t(net\n')[1:]:
    name = re.search(r'\(name "([^"]+)"\)', block).group(1)
    nodes = set(re.findall(r'\(ref "([^"]+)"\)\s*\(pin "([^"]+)"\)', block))
    pads = {(f.GetReference(),p.GetNumber()) for f in b.GetFootprints() for p in f.Pads() if p.GetNetname()==name}
    if nodes != pads: mism.append((name, sorted(nodes-pads), sorted(pads-nodes)))
print('NET MISMATCHES', mism)
for t in b.GetTracks():
    if t.Type()==pcbnew.PCB_VIA_T:
        print('VIA',t.GetNetname(),'drill',pcbnew.ToMM(t.GetDrillValue()),'diameter',pcbnew.ToMM(t.GetWidth(pcbnew.F_Cu)))
