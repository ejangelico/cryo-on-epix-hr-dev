import numpy as np

t = np.zeros(4096, dtype=int)

#generates a ramp
for i in range (0,4096):
    t[i]=i

np.savetxt("ramp128_20bit.csv", (t%128)*(262144/64)+0, fmt='%d')

#generates a sin
#s = np.sin(t*2*3.14159265/128)*(262144/2)+(262144)
s = np.sin(t*2*3.14159265/128)*(262144/2)+(202144)

np.savetxt("sin20bit.csv", s, fmt='%d')

