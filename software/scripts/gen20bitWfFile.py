import numpy as np

t = np.zeros(4096, dtype=int)

#generates a ramp
for i in range (0,4096):
    t[i]=i

np.savetxt("ramp128_20bit.csv", (t%128)*(262144/64)+0, fmt='%d')

#generates a sin
#s = np.sin(t*2*3.14159265/128)*(262144/2)+(262144)
#s = np.sin(t*2*3.14159265/128)*(322144/2)+(220000)


## 5kHz Filter
#s = np.sin(t*2*np.pi/128)*(322144/2)+(220000) # 5kHz Filter
#np.savetxt("sin20bit_Ampl1v52_Mean1v06_pi_5kHzFilt.csv", s, fmt='%d')

## 5kHz Filter - DUNE Range
#s = np.sin(t*2*np.pi/128)*(300000/2)+(229000) # 5kHz Filter
#np.savetxt("sin20bit_Ampl1v52_Mean1v06_pi_5kHzFilt_DUNE_Range.csv", s, fmt='%d')

## 7kHz Filter silMica- DUNE Range
s = np.sin(t*2*np.pi/128)*(310000/2)+(259000) # 5kHz Filter
np.savetxt("sin20bit_Ampl1v52_Mean1v06_pi_7kHzFiltSilMica_DUNE_Range.csv", s, fmt='%d')



## Bessel Filter 5.5kHz
#s = np.sin(t*2*np.pi/128)*(899999/2)+(595000) # For 3r order Bessel Filter @ 5.5kHz
#np.savetxt("sin20bit_Ampl1v52_Mean1v06_pi_BessFilt.csv", s, fmt='%d')

## Bessel Filter 5.5kHz - DUNE Range
#s = np.sin(t*2*np.pi/128)*(820000/2)+(595000) # For 3r order Bessel Filter @ 5.5kHz
#np.savetxt("sin20bit_Ampl1v52_Mean1v06_pi_BessFilt_DUNE_Range.csv", s, fmt='%d')




