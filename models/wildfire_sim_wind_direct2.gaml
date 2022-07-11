/**
* Name: wildfiresim
* Cuban wildfire behavior simulator. A cuban case study
* Author: Tachiri
* Tags: 
*/



model wildfiresim



global {
	// GIS 
	grid_file grid_data <- grid_file("../includes/Sagua de Tánamo/Sagua de Tánamo.tif");	// File containing the GIS information
	geometry shape <- envelope(grid_data);	// Computation of the environment size from the geotiff file	
	
	// Cells max and min values. Used to create a visual reference for altitude
	float min_value;
	float max_value;
	
	
	// Fire related
	int cells_on_fire <- 1;	// Number of cells on fire
	int cells_burned <- 1;	// Number of cells burned
	cell fire_source <- one_of(cell);

	
	// Fuel related
	float fuel_base <- 0.85	min:0.0 max:1.0;	// Base fuel. Related to fuel internal composition and surface
	float fuel_humid <- 0.5	min:0.0 max:1.0;	// Humidity of the fuel
	float diminish_factor <- 0.01	min:0.0 max:1.0;	// Factor for diminishing fire intensity
	
	
	// Weather related
	float temp <- 0.5	min:0.0 max:1.0;
	float wind_speed <- 0.5	min:0.0 max:1.0;
	float relat_humid <- 0.5	min:0.0 max:1.0;
	string wind_direction <- 'N'	among:['N', 'E', 'S', 'W'];
	
	
	// Data related
	float mean_fire_intensity <- 0.0;
	
		
		
	init {
		// Gets the max and min elevation in order to create the scale
		min_value <- cell min_of (each.grid_value);
		max_value <- cell max_of (each.grid_value);
		
		fire_source.on_fire <- true;
		
		
		// Creates a grey scale visual reference for altitude
		ask cell {
			int val <- int(255 * ( 1  - (grid_value - min_value) / (max_value - min_value) ) );
			
			color <- rgb(val, val, val);
		}
	}	
		
	
	reflex stop_sim {
		if(cells_on_fire >= 300 * 250) {
			do pause;
		}
	}
	
	reflex data_obtention {
		float sum <- 0.0;
		list<cell> fires <- (cell where each.on_fire);
		
		loop f	over: fires {
			sum <- sum + f.fire_intensity;
		}
		
		mean_fire_intensity <- sum / length(fires);
	}
	
	reflex save_data {
		save [cycle, cells_on_fire, cells_burned, mean_fire_intensity]	to:"../results/data.csv" type:csv rewrite:false;
	}
}



// Grid species representation of the environment
grid cell	file:grid_data {
	// Agent related
	list<cell> neighbors1 <- (self neighbors_at 1);
	

	// Fuel
	float fuel <- fuel_base	- fuel_humid;
	
	
	// Fire
	bool on_fire <- false;
	bool burned <- false;
	float fire_intensity <- fuel * (0.175 + 0.075)	min:0.0 max:1.0 update:(!on_fire)? (fuel + 0.15 - 0.09) * (0.175 + 0.075) : 0.0;



	user_command "Set_on_fire"	action:set_fire;


	action set_fire {
		on_fire <- true;
	}


	reflex propagate	when:on_fire {
		list<cell> neigh <- neighbors1 where (!each.on_fire and !each.burned);
		cell n <- one_of(neigh);
		
		
		if(n != nil) {
			switch wind_direction {
				match 'N' {
					if(n.grid_y > self.grid_y) {
						n.fire_intensity <- n.fire_intensity + 0.1;
					}
				}
				match 'E' {
					if(n.grid_x < self.grid_x) {
						n.fire_intensity <- n.fire_intensity + 0.1;
					}
				}
				match 'S' {
					if(n.grid_y < self.grid_y) {
						n.fire_intensity <- n.fire_intensity + 0.1;
					}
				}
				match 'W' {
					if(n.grid_x > self.grid_x) {
						n.fire_intensity <- n.fire_intensity + 0.1;
					}
				}
			}
		}
		
		if(n != nil and flip(n.fire_intensity) ) {
			ask n {
				do set_fire;
			}
			
			cells_on_fire <- cells_on_fire + 1;
		}	
	}


	reflex update_color {
		if(on_fire) {
			color <- rgb(255 * fire_intensity, 0, 0);
		} else if(burned) {
			int val <- int(255 * ( 1  - (grid_value - min_value) / (max_value - min_value) ) );
		
			color <- rgb(val, val, val - 100);
		}
    }
    
    reflex fuel_regulation	when:on_fire {
		fuel <- fuel - diminish_factor;
    }
    
   	reflex burned {
   		if(fuel > 0.0) {
   			burned <- false;
   		} else if (!burned) {
   			on_fire <- false;
   			burned <- true;
   			cells_burned <- cells_burned + 1;
   		}
   	}
}



experiment wildfiresim	type:gui {
	parameter "Combustible base"	var:fuel_base min:0.0 max:1.0 category:"Combustible";
	parameter "Contenido de humedad del combustible"	var:fuel_humid	min:0.0 max:1.0 category:"Combustible";
	parameter "Factor de disminución de la combustión"	var:diminish_factor min:0.0 max:1.0 category:"Combustible";
	
	parameter "Temperatura"	var:temp min:0.0 max:1.0 category:"Clima";
	parameter "Humedad relativa"	var:relat_humid min:0.0 max:1.0 category:"Clima";
	parameter "Dirección del viento"	var:wind_direction category:"Clima";
	parameter "Velocidad del viento"	var:wind_speed min:0.0 max:50.0 category:"Clima";
	
	
	
	output {
		// Main display
		display GIS_representation {
			grid cell	lines:#black;
		}
		
		// Data charts
		display dc1	refresh:every(5#cycles) {
			chart "Estado del incendio"	type:series {
				data "Celdas en llamas"	value:cells_on_fire;
				data "Celdas quemadas"	value:cells_burned;
			}
		}
		display dc2 refresh:every(5#cycles) {
			chart "Intensidad del fuego"	type:series {
				data "Promedio"	value:mean_fire_intensity;
			}
		}
		
		
		
		// Monitors
		monitor "Número de celdas en llamas"	value:cells_on_fire;
		monitor "Number de celdas quemadas"	value:cells_burned;
		monitor "Intensidad promedio del fuego"	value:mean_fire_intensity;
	}
}
