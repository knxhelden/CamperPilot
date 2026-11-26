Add-Type -AssemblyName System.Drawing
$data = Get-Content 'pcb-review-geometry.json' -Raw | ConvertFrom-Json
foreach ($region in @(@('regulator',18,85,58,139),@('sensor',132,119,146,140),@('rs485',111,38,128,53))) {
 $scale=22; $x0=[double]$region[1]; $y0=[double]$region[2]
 $bmp=[System.Drawing.Bitmap]::new([int](($region[3]-$x0)*$scale),[int](($region[4]-$y0)*$scale))
 $g=[System.Drawing.Graphics]::FromImage($bmp); $g.Clear([System.Drawing.Color]::White)
 foreach($t in $data.tracks) {
  $color=if($t.layer -eq 'F.Cu'){[System.Drawing.Color]::FromArgb(190,230,100,100)}else{[System.Drawing.Color]::FromArgb(150,90,120,230)}
  $pen=[System.Drawing.Pen]::new($color,[single]($t.w*$scale))
  $g.DrawLine($pen,[single](($t.a[0]-$x0)*$scale),[single](($t.a[1]-$y0)*$scale),[single](($t.b[0]-$x0)*$scale),[single](($t.b[1]-$y0)*$scale)); $pen.Dispose()
 }
 $font=[System.Drawing.Font]::new('Arial',8)
 foreach($p in $data.pads) {
  $x=($p.xy[0]-$x0)*$scale; $y=($p.xy[1]-$y0)*$scale
  $g.FillEllipse([System.Drawing.Brushes]::DarkGoldenrod,[single]($x-3),[single]($y-3),6,6)
  $g.DrawString(($p.ref+'.'+$p.pin),$font,[System.Drawing.Brushes]::Black,[single]($x+3),[single]$y)
 }
 foreach($v in $data.vias){$g.DrawEllipse([System.Drawing.Pens]::Green,[single](($v.xy[0]-$x0)*$scale-5),[single](($v.xy[1]-$y0)*$scale-5),10,10)}
 $bmp.Save((Join-Path $PWD ('pcb-review-'+$region[0]+'.png'))); $g.Dispose(); $bmp.Dispose()
}
