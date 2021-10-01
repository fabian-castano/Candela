using NSGAII
using Random: bitrand
using LinearAlgebra: dot
using DelimitedFiles
using Plots: scatter3d
using PyPlot

function distance(x1,x2)
	return sqrt((x1[1]-x2[1])^2+(x1[2]-x2[2])^2)
end

function plot_pop(P)
    clf() #clears the figure
    P = filter(indiv -> indiv.rank == 1, P) #keep only the non-dominated solutions
    scatter3d(map(x -> x.y[1], P), map(x -> x.y[2], P),  map(x -> x.y[3], P), markersize = 1) |> display
    #plot(map(x -> x.y[1], P), map(x -> x.y[2], P), "bo", markersize = 1)
    sleep(0.1)
end

function two_bits_flip!(bits)
    for i = 1:2
        n = rand(1:length(bits))
        bits[n] = 1 - bits[n]
    end
end

function one_point_crossover!(parent_a, parent_b, child_a, child_b)
    n = length(parent_a)
    cut = rand(1:n-1)

    child_a[1:cut] .= parent_a[1:cut]
    child_a[cut+1:n] .= parent_b[cut+1:n]

    child_b[1:cut] .= parent_b[1:cut]
    child_b[cut+1:n] .= parent_a[cut+1:n]
end

function binary_mask_crossover!(parent_a, parent_b, child_a, child_b)
    n = length(parent_a)
    mask = bitrand(n)

    child_a.= parent_a.*mask +parent_b.*(ones(n).-mask)
    child_b.= parent_a.*(ones(n).-mask)+parent_b.*mask
end

filename="c://Users/fanca/Downloads/demofile2.txt"
data=readdlm(filename)

Hubs=data[1,1]+1
Targets=data[1,2]

Rc=data[1,3]
Rs=data[1,4]

x_coors=data[2:Hubs+1,1]
y_coors=data[2:Hubs+1,2]

x_tar=data[Hubs+2:Hubs+Targets+1,1]
y_tar=data[Hubs+2:Hubs+Targets+1,2]

Adj1,Adj2=zeros(Hubs,Targets),zeros(Hubs,Targets)

for i in 1:Hubs, j in 1:Targets
    if distance([x_coors[i],y_coors[i]],[x_tar[j],y_tar[j]])<=Rs
        Adj1[i,j]=1
    end
    if distance([x_coors[i],y_coors[i]],[x_tar[j],y_tar[j]])<=Rc
        Adj2[i,j]=1
    end
end



z(x) = sum(transpose(Adj1)*x.>=1), -1*sum(x),sum(transpose(Adj2)*x.>=1)



print("Mi primer resultado ====")


popsize = 50
nbgen = 200
init() = bitrand(Hubs) #our genotype is a binary vector of size n, initialized randomly

x1=bitrand(Hubs)
println(z(x1))
#result = nsga_max(popsize, nbgen, z, init)

result=nsga_max(popsize, nbgen, z, init,  fcross = binary_mask_crossover!, fmut = two_bits_flip!, pmut = 0.2,fplot = plot_pop, plotevery = 5)

print(result)
out = sort(result, by = ind -> ind.y[1])[end];
println("x = $(out) ")
"""
function CV(x)
    sumW = dot(x, w)
    return sumW <= c ? 0 : sumW - c
end

#We can now call
result = nsga_max(popsize, nbgen, z, init, fCV = CV)

x1 = greedy(p1, w, c)
x2 = greedy(p2, w, c)
x3 = greedy(p1 .+ p2, w, c)

nsga_max(popsize, nbgen, z, init, fCV = CV, fcross = one_point_crossover!, fmut = two_bits_flip!, pmut = 0.2,seed = [x1, x2, x3])

using PyPlot



nsga_max(popsize, nbgen, z, init, fCV = CV, fcross = one_point_crossover!, fmut = two_bits_flip!, pmut = 0.2,seed = [x1, x2, x3],fplot = plot_pop, plotevery = 5)
"""