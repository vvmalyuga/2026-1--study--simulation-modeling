using Agents, Random, Agents.Graphs, StatsBase, Distributions

@agent struct Person(GraphAgent)
    days_infected::Int
    status::Symbol
end

function initialize_sir_quarantine(; Ns=[1000,1000,1000], migration_rates=nothing,
    β_und=[0.5,0.5,0.5], β_det=[0.05,0.05,0.05], infection_period=14,
    detection_time=7, death_rate=0.02, reinfection_probability=0.1,
    Is=[1,0,0], seed=42, quarantine_threshold=0.1)
    
    rng = Xoshiro(seed)
    C = length(Ns)
    if migration_rates === nothing
        migration_rates = zeros(C,C)
        for i in 1:C, j in 1:C
            migration_rates[i,j] = (Ns[i]+Ns[j])/Ns[i]
        end
        for i in 1:C
            migration_rates[i,:] ./= sum(migration_rates[i,:])
        end
    end
    properties = Dict(:Ns=>Ns, :β_und=>β_und, :β_det=>β_det, :migration_rates=>migration_rates,
        :infection_period=>infection_period, :detection_time=>detection_time,
        :death_rate=>death_rate, :reinfection_probability=>reinfection_probability,
        :C=>C, :quarantine_threshold=>quarantine_threshold, :closed_cities=>falses(C))
    space = GraphSpace(complete_graph(C))
    model = StandardABM(Person, space; properties, rng, agent_step! = sir_agent_step_quarantine, model_step! = sir_model_step_quarantine)
    for city in 1:C
        for _ in 1:Ns[city]
            add_agent!(city, model, 0, :S)
        end
    end
    for city in 1:C
        if Is[city] > 0
            ids = ids_in_position(city, model)
            infected_ids = sample(rng, ids, Is[city]; replace=false)
            for id in infected_ids
                model[id].status = :I
                model[id].days_infected = 1
            end
        end
    end
    return model
end

function sir_agent_step_quarantine(agent, model)
    migrate_quarantine!(agent, model)
    if agent.status == :I
        transmit!(agent, model)
        agent.days_infected += 1
    end
    if agent.status == :I && agent.days_infected ≥ model.infection_period
        if rand(abmrng(model)) ≤ model.death_rate
            remove_agent!(agent, model)
        else
            agent.status = :R
            agent.days_infected = 0
        end
    end
end

function migrate_quarantine!(agent, model)
    current = agent.pos
    # Если город закрыт, миграция запрещена
    if model.closed_cities[current]
        return
    end
    probs = model.migration_rates[current, :]
    target = sample(abmrng(model), 1:model.C, Weights(probs))
    if target != current
        move_agent!(agent, target, model)
    end
end

function sir_model_step_quarantine(model)
    # Проверяем уровень заболеваемости в каждом городе
    for city in 1:model.C
        agents = [a for a in allagents(model) if a.pos == city]
        n_inf = count(a.status == :I for a in agents)
        total = length(agents)
        if total > 0 && n_inf/total > model.quarantine_threshold
            model.closed_cities[city] = true
        end
    end
end

# Переиспользуем transmit! из оригинальной модели (можно скопировать)
function transmit!(agent, model)
    rate = agent.days_infected < model.detection_time ? model.β_und[agent.pos] : model.β_det[agent.pos]
    n_infections = rand(abmrng(model), Poisson(rate))
    n_infections == 0 && return
    neighbors = [a for a in agents_in_position(agent.pos, model) if a.id != agent.id]
    shuffle!(abmrng(model), neighbors)
    for contact in neighbors
        if contact.status == :S
            contact.status = :I; contact.days_infected = 1; n_infections -= 1; n_infections == 0 && return
        elseif contact.status == :R && rand(abmrng(model)) ≤ model.reinfection_probability
            contact.status = :I; contact.days_infected = 1; n_infections -= 1; n_infections == 0 && return
        end
    end
end
