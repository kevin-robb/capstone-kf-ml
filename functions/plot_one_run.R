#!/usr/bin/env Rscript

# To use from cmd line, invoke:
# Rscript --vanilla functions/plot_one_run.R "filename" "directory"
# To use in another R/Rmd script:
# source("functions/plot_one_run.R")

# Plot 4-Dimensional Kalman Filter Data from a single run.
#
# Generates a PNG graphing all four KF parameters' 
# measured, predicted, and state values, as well
# as the ground truth for comparison.
#
# Also shows the path followed by the robot (X vs Y),
# and optionally show the measured heading in a separate plot.
#
plot_one_run <- function(filename, dirpath, plot_hdg=FALSE) {
  library(reshape2)
  library(ggplot2)
  library(grid)
  library(gridExtra)
  library(cowplot)
  
  # read in the data from the file
  filepath = paste("./", dirpath, "/", filename, ".csv", sep="")
  df=read.csv(filepath)

  incl_wp=TRUE
  if (incl_wp) {
    # grab the waypoints from their file.
    wp_df=read.csv("./config/waypoints.csv", header=TRUE)

    # add each as a constant value column to df.
    df$wp_x1 <- wp_df$x[[1]]
    #df[["new_column"]] <- "N"
    df$wp_y1 <- wp_df$y[[1]]
    df$wp_x2 <- wp_df$x[[2]]
    df$wp_y2 <- wp_df$y[[2]]
    df$wp_x3 <- wp_df$x[[3]]
    df$wp_y3 <- wp_df$y[[3]]
    df$wp_x4 <- wp_df$x[[4]]
    df$wp_y4 <- wp_df$y[[4]]
    df$wp_x5 <- wp_df$x[[5]]
    df$wp_y5 <- wp_df$y[[5]]
  }

  incl_results=TRUE
  if (incl_results) {
    # grab the pre-processed results
    res_df=read.csv("./config/results.csv", header=TRUE)
    # do not use this data if there was an error
    if (res_df$seed[1] == -1) {
      incl_results=FALSE
    }
  }

  # data file has 18 columns, (will be 19 when timestep is added)
  # meas (4d), pred (4d), state (4d), truth (5d), cur_hdg (1d)
  # plus now 10 more for the waypoints
  meas_names <- c("x_meas","y_meas","xdot_meas","ydot_meas")
  pred_names <- c("x_pred","y_pred","xdot_pred","ydot_pred")
  state_names <- c("x_state","y_state","xdot_state","ydot_state")
  truth_names <- c("x_true","y_true","xdot_true","ydot_true","vel_true")
  yaw_name <- c("cur_hdg")
  wp_names <- c("wp_x1","wp_y1","wp_x2","wp_y2","wp_x3","wp_y3","wp_x4","wp_y4","wp_x5","wp_y5")
  names(df) <- c(meas_names, pred_names, state_names, truth_names, yaw_name, wp_names)

  # add a timestep independent variable
  t = c(1:length(df$x_meas))
  df <- cbind(t, df)
  
  # change the names of df_x since they will be used for the legend
  df_x_pre <- df[,c(1,2,6,10,14)]
  names(df_x_pre) <- c("t","Measured","Predicted","State","Truth")
  
  # subset each variable
  df_x = melt(df_x_pre, id=c("t"))
  df_y = melt(df[,c(1,3,7,11,15)], id=c("t"))
  df_xdot = melt(df[,c(1,4,8,12,16)], id=c("t"))
  df_ydot = melt(df[,c(1,5,9,13,17)], id=c("t"))
  
  # define the first plot (x-position)
  p_x <- ggplot(df_x) + geom_line(aes(x=t,y=value,colour=variable)) +
    scale_colour_manual(values=c("red","blue","green","black")) +
    ggtitle("X Position (m)") + 
    cowplot::theme_minimal_grid(12) +
    theme(axis.text.x = element_text(size = 8, angle = 90, vjust = 0.5),axis.text.y = element_text(size = 8, vjust = 0.5)) +
    theme(plot.title = element_text(size=12))
  # save the legend before suppressing it
  legend <- cowplot::get_legend(p_x)
  p_x <- p_x + theme(legend.position="none") + ylab("") + xlab("timestep")
  
  # define all the other plots (w/o legend)
  p_y <- ggplot(df_y) + geom_line(aes(x=t,y=value,colour=variable)) +
    scale_colour_manual(values=c("red","blue","green","black")) +
    ggtitle("Y Position (m)") + ylab("") + xlab("timestep") +
    cowplot::theme_minimal_grid(12) + theme(legend.position="none") +
    theme(axis.text.x = element_text(size = 8, angle = 90, vjust = 0.5),axis.text.y = element_text(size = 8, vjust = 0.5)) +
    theme(plot.title = element_text(size=12))
  p_xdot <- ggplot(df_xdot) + geom_line(aes(x=t,y=value,colour=variable)) +
    scale_colour_manual(values=c("red","blue","green","black")) + ylab("") + xlab("timestep") +
    ggtitle("X Velocity (m/s)") + theme_minimal_grid(12) + theme(legend.position="none") +
    theme(axis.text.x = element_text(size = 8, angle = 90, vjust = 0.5),axis.text.y = element_text(size = 8, vjust = 0.5)) +
    theme(plot.title = element_text(size=12))
  p_ydot <- ggplot(df_ydot) + geom_line(aes(x=t,y=value,colour=variable)) +
    scale_colour_manual(values=c("red","blue","green","black")) + ylab("") + xlab("timestep") +
    ggtitle("Y Velocity (m/s)") + theme_minimal_grid(12) + theme(legend.position="none") +
    theme(axis.text.x = element_text(size = 8, angle = 90, vjust = 0.5),axis.text.y = element_text(size = 8, vjust = 0.5)) +
    theme(plot.title = element_text(size=12))
  
  # draw the robot's path
  p_t <- ggplot(df) +
    scale_x_reverse() +
    ggtitle("Robot Path (X vs Y)") +
    xlab("Y Position (m)") + ylab("X Position (m)") +
    geom_point(aes(y_true,x_true), color="black",size=0.2,stroke=1,shape=16) +
    geom_point(aes(y_meas,x_meas), color="red",size=0.2,stroke=1,shape=16) +
    geom_point(aes(y_pred,x_pred),color="blue",size=0.2,stroke=1,shape=16) +
    geom_point(aes(y_state,x_state),color="green",size=0.2,stroke=1,shape=16) +
    theme(plot.title = element_text(size=14)) +
    coord_cartesian(xlim = c(25, -25), ylim = c(0, 90)) +
    theme_minimal_grid(12) #+ theme(legend.position="none")
  p_t

  # add the waypoints to the path plot
  if (incl_wp) {
    wp_cols = c("purple","purple","purple")
    # make them a different color based on whether they were successfully hit or not.
    if (incl_results) {
      if (!as.logical(res_df$wp1)) { wp_cols[[1]] = "yellow" }
      if (!as.logical(res_df$wp2)) { wp_cols[[2]] = "yellow" }
      if (!as.logical(res_df$wp3)) { wp_cols[[3]] = "yellow" }
    }
    p_t <- p_t +
      geom_point(aes(wp_y1,wp_x1), color="purple") + #start
      geom_point(aes(wp_y2,wp_x2), color=wp_cols[[1]]) +
      geom_point(aes(wp_y3,wp_x3), color=wp_cols[[2]]) +
      geom_point(aes(wp_y4,wp_x4), color=wp_cols[[3]]) +
      geom_point(aes(wp_y5,wp_x5), color="purple") #goal
  }
  
  # create the "plot" of text
  tex <- ggdraw(plot.new()) + 
    draw_label(paste("",res_df$seed[1],""), x=0, hjust=0, y=1.0, size = 9) +
    draw_label(paste("Obstacles:",res_df$obst[1],""), x=0, hjust=0, y=0.85, size = 9) +
    draw_label(paste("Noise:",res_df$noise[1],""), x=0, hjust=0, y=0.7, size = 9) +
    draw_label(paste("Time:",res_df$time[1],""), x=0, hjust=0, y=0.55, size = 9) +
    draw_label(paste("Score:",res_df$score[1],""), x=0, hjust=0, y=0.4, size = 9)

  ## combine plots
  # legend above text
  leg_tex <- cowplot::plot_grid(legend,tex,ncol=1)

  # main 4 plots (x,y,xdot,ydot) will be left side
  ptl <- cowplot::align_plots(p_x,p_xdot,align='v')
  ptr <- cowplot::align_plots(p_y,p_ydot,align='v')
  pl <- cowplot::plot_grid(ptl[[1]], ptr[[1]], ncol=2)
  pr <- cowplot::plot_grid(ptl[[2]],ptr[[2]], ncol=2)
  p_left <- cowplot::plot_grid(pl,pr,ncol=1)
  
  # track and legend/text will be right side
  p_right <- cowplot::plot_grid(p_t, leg_tex, ncol=2, rel_widths=c(2,1))
  
  if (plot_hdg == TRUE) {
    # make the heading plot
    p_hdg <- ggplot(df) + geom_line(aes(x=t,y=cur_hdg),color="red") + ylab("") + xlab("timestep") +
      ggtitle("Heading") + theme_minimal_grid(12) + theme(legend.position="none") +
      theme(axis.text.x = element_text(size = 8, angle = 90, vjust = 0.5),axis.text.y = element_text(size = 8, vjust = 0.5)) +
      theme(plot.title = element_text(size=12))
    # put it in the right side plot grid
    # right side will be track+legend above heading plot
    p_right <- cowplot::plot_grid(p_right,p_hdg,ncol=1,rel_heights=c(2,1))
  }
  
  # make overall plot
  p_tot <- cowplot::plot_grid(p_left,p_right,ncol=2,rel_widths=c(4,3))
  p_tot
  
  # set plot location
  if (dirpath == "kf_data") {
    # default option
    plot_path = paste("./kf_plots/", filename, ".png", sep="")
  } else {
    # write the plots to the same file the data came from
    plot_path = paste("./", dirpath, "/", filename, ".png", sep="")
  }
  # store the plot PNG
  cowplot::save_plot(plot_path,p_tot,base_height=4,base_width=6.5)
  
}

## Command Line stuff

# grab parameters from command line.
args = commandArgs(trailingOnly=TRUE)

# check number of arguments.
if (length(args)==2) {
  plot_one_run(filename=args[1],dirpath=args[2])
} else if (length(args)==1) {
  # run the script as previously, with one file in the kf_data directory.
  args[2] = "kf_data"
  plot_one_run(filename=args[1],dirpath=args[2])
} else if (length(args)>2) {
  stop("Too many command line arguments", call.=FALSE)
} else { #length(args)==0
  # Comment out this line to be able to source this file
  # and use the function from somewhere besides the cmd line.
  stop("Must supply filename (without extension) and optionally the directory", call.=FALSE)
}
