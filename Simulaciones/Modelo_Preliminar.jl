using JuMP
using Gurobi
using Random
using Plots
using StatsBase

function DrawGrid(A)
    x=1:size(A,1)
    y=1:size(A,1)
    plt =heatmap(x, y, A)#, clims=(0,1))
end

function Initiate1(tam,Rs,S)
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

function Initiate2(tam,Rs,S,loc)
    Vegetacion=rand(tam,tam).<0.5
    Quemados=zeros(tam,tam)
    Sensors=[(loc[1],loc[2]) for i in 1:S]
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

function RunSimulation(Green,Burned,Covered,tam::Int)
    xini,yini=rand(1:tam),rand(1:tam)
    Burned[xini,yini]=1
    Priority=zeros(tam,tam)
    coverage=[sum(Burned)/sum(Green)]

    step=1
    
    detected=[]
    tot_det=0
    
    #=if Covered[xini,yini]==0
        push!(detected,tot_det)
    else
        tot_det+=1
        push!(detected,tot_det/sum(Burned))
    end=#

    while true
    
        susceptibles=[]
        
        for i in xini-1:xini+1, j in yini-1:yini+1 
            if i>0 && i<=tam && j>0 && j<=tam && (xini,yini)!=(i,j) && Burned[i,j]==0 && Green[i,j]==1 
            push!(susceptibles,(i,j))            
            end 
        end
        
        if length(susceptibles)>0 
            elegido=rand(susceptibles)
            xini,yini=elegido[1],elegido[2]
            Burned[xini,yini]=step+1
            Priority[xini,yini]=1/Burned[xini,yini]
            step=step+1
            
                if Covered[xini,yini]==2
                Burned[e[1],e[2]]=1
                tot_det+=1
            end
        else
            break
        end
    end
     
    push!(coverage,sum(Burned)/sum(Green))
    push!(detected, tot_det/sum(Burned)) 
    
    return Priority,Burned,coverage,detected
end

function Matriz_Cubiertos(tam,r)
    
    L=1:tam^2
    M=1:tam^2

    # Ubicación de los sensores    100
    L=[(i,j) for j in 1:tam, i in 1:tam]

    # Ubicación de la cuadrícula
    M=[(i,j) for j in 1:tam, i in 1:tam]

    B=zeros(Int8,tam^2,tam^2)

    for l in 1:tam^2
        l1=L[l]       
            for m in 1:tam^2
             m1=M[m]
                if ((l1[1]-m1[1])^2 + (l1[2]-m1[2])^2)<=r^2
                   B[l,m]=1
                else
                    B[l,m]=0
                end
            end
    end
    
    return B
end

function Create_model(P,B,num_sensores)
    
    location=[]
    modelop=Model(Gurobi.Optimizer)

    @variable(modelop,x[1:length(P)],Bin) #Si en zona l hay un sensor
    @variable(modelop,y[1:length(P)],Bin) #Si zona m está cubierto 
     
    for m in 1:length(P)
        @constraint(modelop,sum(x[l]*B[l,m] for l in 1:length(P))>=y[m])
    end
    
    @constraint(modelop,sum(x[l] for l in 1:length(P))<=num_sensores)
    @objective(modelop,Max,sum([y[m]*P[m] for m in 1:length(P)]))
    
    optimize!(modelop)

    for i in 1:length(P)
        if value.(x)==1.0 
            push!(location,(x[1],x[2]))
        end
    end

    return location

end

#Indicadores iniciales
Total_Coverage1=[] #Total área quemada
Total_Detected1=[] #Total área detectada
Total_THD1=[] #Total tiempo hasta detección
Total_QHD1=[] #Total área quemada hasta detección

#Indicadores despúes de optimización
Total_Coverage2=[] #Total área quemada
Total_Detected2=[] #Total área detectada
Total_THD2=[] #Total tiempo hasta detección
Total_QHD2=[] #Total área quemada hasta detección

#Parámetros de entrada
radio=1 #Radio sensor en cuadrícula
tamano=200 #Tamaño cuadrícula
s=1:200 #Número de sensores

for sensores in s

    MC=Matriz_Cubiertos(tamano,radio)

    for exp in 1:1

        Veg_arbol,quemado,cubierto=Initiate1(tamano,radio,sensores)
        DrawGrid(Veg_arbol+cubierto) 
        Matriz_prioridades,Periodo_incendio,AreaQ,AreaDetected=RunSimulation(Veg_arbol,quemado,cubierto,tamano)
      
        push!(Total_Coverage1,AreaQ)
        push!(Total_Detected1,AreaDetected)
        
        pos1=count(i->( i== 0),AreaDetected )

            if pos1>0
                push!(Total_THD1,pos1)
                push!(Total_QHD1,round(AreaQ[pos1]*100;digits=3))
            end

        #Ejecuta modelo de optimización
        
        Create_model(Matriz_prioridades,MC,sensores)
        
        #Ejecuta simulación con ubicación óptima

        Veg_arbol,quemado,cubierto=Initiate2(tamano,radio,sensores,location)
        DrawGrid(Veg_arbol+cubierto) 
        Matriz_prioridades,Periodo_incendio,AreaQ,AreaDetected=RunSimulation(Veg_arbol,quemado,cubierto,tamano)

        push!(Total_Coverage2,AreaQ)
        push!(Total_Detected2,AreaDetected)
        
        pos2=count(i->( i== 0),AreaDetected )

            if pos2>0
                push!(Total_THD2,pos2)
                push!(Total_QHD2,round(AreaQ[pos2]*100;digits=3))
            end    
    end

end
    
#Plot de situación inicial

pltInicial1=plot(s,round.(Total_Coverage1*100;digits=3),label="% Quemado")
pltInicial2=plot(s,round.(Total_Detected1*100;digits=3),label="% Detectado")
pltInicial3=plot(s,Total_THD1,label="Tiempo hasta detección")
pltInicial4=plot(s,Total_QHD1,label="% quemado hasta detección")

display(pltInicial1,pltInicial2,pltInicial3,pltInicial4)

#Plot después de optimizar ubicaciones

pltFinal1=plot(s,round.(Total_Coverage2*100;digits=3),label="% Quemado")
pltFinal2=plot(s,round.(Total_Detected2*100;digits=3),label="% Detectado")
pltFinal3=plot(s,Total_THD2,label="Tiempo hasta detección")
pltFinal4=plot(s,Total_QHD2,label="% quemado hasta detección")

display(pltFinal1,pltFinal2,pltFinal3,pltFinal4)


