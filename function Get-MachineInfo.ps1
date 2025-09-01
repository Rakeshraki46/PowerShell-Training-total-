'5' -eq 'five'

"33" -eq 33


$now = Get-Date
if ($now.DayOfWeek -eq 'tuesday' -OR $now.hour -gt 7) {
    Write-Output "It's tuesday evening!"
}else{
    Write-Output "its not evening"
}
$numbers=1..10
$data = foreach ($n in $numbers) {
 $n*3
}
$data | out-file data.txt


$x = "1d1234345678"
switch -wildcard ($x)
 {
 "*2*" { "-Contains 2"}
 "*5*" {"Contains 5"}
 "*d*" {"Starts with 'd'"}
 default {"No matches"}
 }

 #While ($true) {
 #   $choice = Read-Host "Enter a number."
  #  If ($choice –eq 0) { break }
  # }

  foreach($file in get-childitem)  {
    Write-Output "$file"
  }

  $fruits= "apple", "orange", "guava", "pomegranate", "Mango"  
  foreach ($item in $fruits)  {
  Write-Output "$item"
  }
$x=5
#$i=1
$sum=1
  while($sum -le 5)  {
  $sum = $i * $x
  Write-Output "print $sum"
  $sum+=1
  #Write-Output "print $i"
  }