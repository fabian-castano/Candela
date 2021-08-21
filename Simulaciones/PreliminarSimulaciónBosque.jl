using Random
using Plots

function DrawGrid(A)
    x=1:size(A,1)
    y=1:size(A,1)
    plt =heatmap(x, y, A)#, clims=(0,1))
end

function inicializar(tam,Rs,S)
    Vegetacion=rand(tam,tam).<0.5
    Quemados=zeros(tam,tam)
    Sensors=[(rand(1:tam),rand(1:tam)) for i in 1:S]
    Covered=zeros(tam,tam)

    for i in 1:tam,j in 1:tam
        for s in Sensors
            if (s[1]-i)^2+(s[2]-j)^2<=Rs^2
                Covered[i,j]=2
            end
        end
    end
    
    return Vegetacion, Quemados, Covered
end

function RunSimulation(Green,Burned,Covered)
    tam=size(Green,1)
    xini,yini=rand(1:tam),rand(1:tam)
    Burned[xini,yini]=1

    coverage=[sum(Burned)/sum(Green)]

    detected=[]
    tot_det=0
    if Covered[xini,yini]==0
        push!(detected,tot_det)
    else
        tot_det+=1
        push!(detected,tot_det/sum(Burned))
    end


    anim = @animate for rep in 1:100
        list_burned=[]
        for i in 1:tam,j in 1:tam
            if Green[i,j] ==1 && Burned[i,j]==0 && 0<sum([Burned[i1,j1]*(rand()<0.3) for i1 in i-1:i+1 for j1 in j-1:j+1 if i1>0 && i1<=tam && j1>0 && j1< tam])
                push!(list_burned,(i,j))
            end
        end
        for e in list_burned
            Burned[e[1],e[2]]=1

            if Covered[e[1],e[2]]==2
                Burned[e[1],e[2]]=1
                tot_det+=1
            end
        end

        push!(coverage,sum(Burned)/sum(Green))
        push!(detected, tot_det/sum(Burned))
        DrawGrid(Burned)
    end

    gif(anim, "anim_fps15.gif", fps = 15)  
    
    #println("Porcentaje quemado: ",round.(coverage*100;digits=2))
    #println("Porcentaje detectado: ",round.(detected*100;digits=2))
    return coverage, detected
end

tam=200
Rs=25
Sensors=10

for exp in 1:1
    Green,Burned,Covered=inicializar(tam,Rs,Sensors)
    DrawGrid(Covered+Green) 
    coverage, detected=RunSimulation(Green,Burned,Covered)
    plt=plot(round.(coverage*100;digits=3),label="% Quemado")
    plot!(round.(detected*100;digits=3),label="% Detectado")
    display(plt)
    
    savefig(plt,"fig1.png")
    pos=count(i->( i== 0),detected )
    if pos>0
        println(" Tiempo hasta detección: ",pos," % quemado hasta detección: ",round(coverage[pos]*100;digits=3))
    end
end
