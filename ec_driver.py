# This file creates and manages the set of agents, and assigns fitness.

from functions import read_results
from ec_agent import Agent
from typing import List, Tuple
from random import choices
from datetime import datetime
import subprocess
#from os import path, mkdir

def initialize_agents(roster_size:int, next_id:List[int]) -> List:
    roster = []
    for _ in range(roster_size):
        roster.append(Agent(next_id[0]))
        next_id[0] += 1
    return roster

def next_generation(roster:List, next_id:List[int]) -> List:
    # sort this generation by fitness. (smaller = better)
    roster.sort(key=lambda a: a.fitness) #reverse=True
    # define the weights for each position. for now, simple linear decrease.
    r_weights = [len(roster)-i for i in range(len(roster))]
    # select double what is needed to parent the next generation. (agents can/will be multi-selected)
    parents = choices(roster, weights=r_weights, k=2*len(roster))
    # create the next generation by crossing over pairs of parents.
    next_gen = [parents[i].group_crossover(parents[i + len(roster)], next_id) for i in range(len(roster))]
    return next_gen

def setup_summary_file(directory:str, run_id:str) -> str:
    filepath = directory + "/summary_" + run_id + ".csv"
    # create the file and write the header to the first line.
    header = ["agent_id","generation_number","p_11","p_22","p_33","p_44","q_11","q_22","q_33","q_44","r_11","r_22","r_33","r_44","fitness"]
    file1 = open(filepath, "a+")
    file1.write(",".join(header) + "\n")
    return filepath

def setup_dir() -> Tuple:
    # make a unique ID for tracking this run's files.
    dt = datetime.now()
    run_id = dt.strftime("%Y-%m-%d-%H-%M-%S")
    # make a directory to store KF data, gen summaries, and plots.
    directory = "runs/run_" + run_id
    run_bash_cmd("mkdir " + directory)
    #parent_dir = "/home/kevinrobb/capstone-kf-ml/runs/"
    #path = path.join(parent_dir, directory) 
    #mkdir(path)
    # create the summary file for this run and return the filepath.
    return directory, setup_summary_file(directory, run_id)

def run_bash_cmd(command:str):
    # run something on the command line.
    process = subprocess.Popen(command.split(), stdout=subprocess.PIPE) #cwd='path\to\somewhere'
    output, error = process.communicate()
    
def main():
    # size of each gen, # of gens to run.
    gen_size, gen_max = 5, 3
    # create the folder/file we will use for this run's data.
    directory, summary_filepath = setup_dir()
    # ensure each agent gets a different ID. 
    # this is a list with one element so it can be changed inside functions.
    next_id = [1]
    # create the first generation of agents, with default values.
    roster = initialize_agents(gen_size, next_id)

    # run the sim for each agent to obtain fitness for each.
    while roster[0].gen_num <= gen_max:
        # TODO look into using the same seed for agents in the same generation.
        for agent in roster:
            # set the KF to use this agent's genome params.
            agent.set_genome()
            # call the bash script to run the sim.
            # need to pass in the directory and a filename for the KF data to output to.
            run_bash_cmd("bash run_sim.sh " + directory + " kf_output_" + agent.id)            
            # assign the agent a fitness based on the results.
            agent.results = read_results.read_file()
            agent.fitness = agent.results["Score"]
            # write this agent & its performance to the file.
            agent.write_to_file(summary_filepath)
        # form the next generation.
        roster = next_generation(roster, next_id)

    # after repeating for the desired number of generations, run our plotting script.
    run_bash_cmd("Rscript --vanilla functions/plot_cl_fitness.R " + summary_filepath + " true")
    # TODO also plot the best agent in the final generation using my previous in-depth script.

if __name__ == "__main__":
    main()
