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
	cell fire_source <- one_of(cell);	// Fire source. Random position on the raster

	
	// Fuel related
	float base_fuel <- 0.85	min:0.0 max:1.0;	// Base fuel. Related to fuel internal composition
	float diminish_factor <- 0.01	min:0.0 max:0.3;	// Factor for diminishing fire intensity
	
	
	// Weather related
	int humidity <- 75	min:50 max:100;
	int wind_direction <- 0	min:0 max:360;
	float wind_speed <- 15.0	min:0.0 max:50.0;
	float temperature <- 25.0	min:0.0 max:40.0;
	
	
	// Data related
	float mean_fire_intensity <- 0.0;
	
		
		
	init {
		// Gets the max and min elevation in order to create the scale
		min_value <- cell min_of (each.grid_value);
		max_value <- cell max_of (each.grid_value);
		
		// Starts a fire
		fire_source.on_fire <- true;
		
		
		// Creates a grey scale visual reference for altitude
		ask cell {
			int val <- int(255 * ( 1  - (grid_value - min_value) / (max_value - min_value) ) );
			
			color <- rgb(val, val, val);
		}
	}	
		
	
	reflex upd_sim {
//		write fire_source.grid_x;
//		write fire_source.grid_y;
//		write fire_source.on_fire;
//		write fire_source.fuel;
//		write fire_source.fire_intensity;
		
		
		list<cell> fires <- (cell where each.on_fire);
		
		loop f	over: fires {
			cell neigh <- one_of(f.neighbors1 where (!each.on_fire and !each.burned) );
			
			if(neigh != nil and flip(f.fire_intensity) ) {
				neigh.on_fire <- true;
				
				cells_on_fire <- cells_on_fire + 1;
			}
		} 
		
		if(cycle = 300 or cells_on_fire >= 300 * 250) {
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
}



// Grid species representation of the environment
grid cell	file:grid_data {
	// Agent related
	list<cell> neighbors1 <- (self neighbors_at 1);
	

	// Fuel
	float fuel <- base_fuel	min:0.0 max:1.0;
	
	
	// Fire
	bool on_fire <- false;
	bool burned <- false;
	float fire_intensity <- (fuel + 0.18 - 0.09) * (0.175 + 0.075)	min:0.0 max:1.0 update:(on_fire)? (fuel + 0.15 - 0.09) * (0.175 + 0.075) : 0.0;



	reflex update_color {
		if(on_fire) {
			color <- rgb(255 * fire_intensity, 0, 0);
		} else if(burned) {
			int val <- int(255 * ( 1  - (grid_value - min_value) / (max_value - min_value) ) );
			
			//color <- rgb(val - 100, val - 100 , val - 100);
			color <- rgb(val, val, val - 100);
		}
    }
    
    reflex fuel_regulation {
    	if(on_fire) {
    		fuel <- fuel - diminish_factor;
    	}
    }
    
   	reflex burned {
   		if(fuel > 0.0) {
   			burned <- false;
   		} else {
   			on_fire <- false;
   			burned <- true;
   			cells_burned <- cells_burned + 1;
   		}
   	}
    
//    reflex smokey {
//		if(!on_fire) {
//			fire_intensity <- length(neighbors1 where each.on_fire) * 35;
//		}
//    }
}



experiment wildfiresim	type:gui {
	parameter "Combustible base"	var:base_fuel min:0.0 max:0.3 category:"Combustibles";
	parameter "Factor de disminución de la combustión"	var:diminish_factor min:0.0 max:0.3 category:"Combustibles";
	
	parameter "Humedad"	var:humidity min:50 max:100 category:"Clima";
	parameter "Dirección del viento"	var:wind_direction min:0 max:360 category:"Clima";
	parameter "Velocidad del viento"	var:wind_speed min:0.0 max:50.0 category:"Clima";
	parameter "Temperatura"	var:temperature min:0.0 max:40.0 category:"Clima";
	
	
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
