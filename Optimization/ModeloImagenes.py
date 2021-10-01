from PIL import Image

import matplotlib.pyplot as plt
import matplotlib.image as mpimg

import gurobipy as gp
from gurobipy import GRB

im = Image.open('c:\\Users\\fanca\\Downloads\\LaPrimavera.PNG') # Can be many different formats.
pix = im.load()

gray ={ (i,j): 255-int(0.2989 * pix[(i,j)][0] + 0.5870 * pix[(i,j)][1] + 0.1140 * pix[(i,j)][2]) for i in range(im.size[0]) for j in range(im.size[1])}




# list of indices of variables b[i]
model = gp.Model('ConstraintOptimization')
model.ModelSense = GRB.MINIMIZE
y=model.addVars( gray.keys(),vtype=GRB.BINARY, name="y")

model.setObjective(gp.quicksum(y[e]*(255-gray[e])+(1-y[e])*(gray[e]) for e in gray.keys()) )

model.addConstr(gp.quicksum(y[e] for e in gray.keys())<=25000)

model.addConstrs((gp.quicksum(y[(i,j)] for i in range(e[0]-1,e[0]+2) for j in range(e[1]-1,e[1]+2) )<=5 for e in gray.keys() if e[0]>0 and e[0]<im.size[0]-1 and e[1]>0 and e[1]<im.size[1]-1), name='departments_limit')

model.optimize()

f = open("c:\\Users\\fanca\\Downloads\\demofile2.txt", "a")

for i in range(im.size[0]):
    for j in range(im.size[1]):
        
        pixel = (1-y[(i,j)].x)*255
        pix[i,j]=(int(pixel),int(pixel),int(pixel))
        if (1-y[(i,j)].x)==0:
            f.write(str(i)+" "+str(j)+" "+str(1)+"\n")
f.close()           
im.save('c:\\Users\\fanca\\Downloads\\LaPrimaveraSalida2.png')
img = mpimg.imread('c:\\Users\\fanca\\Downloads\\LaPrimaveraSalida2.png')
plt.imshow(img)
plt.show()