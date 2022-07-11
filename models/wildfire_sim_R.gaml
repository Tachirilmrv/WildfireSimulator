/**
* Name: wildfiresim
* Cuban wildfire behavior simulator. A cuban case study
* Author: Tachiri
* Tags: 
*/



model wildfiresim



global skills:[RSkill] {
	/* Fuel */
	// Raw
	float raw_fuel_humid <- 75.0;
	
	// Processed
	float fuel_base <- 0.5;
	float diminish_factor <- 0.5;
	
	float fuel_humid;
	
	
	/* Weather */
	// Raw
	float raw_temp <- 20.0;
	float raw_wind_speed <- 25.0;
	float raw_relat_humid <- 75.0;
	
	// Processed
	string wind_direction <- 'N'	among:['N', 'E', 'S', 'W'];

	float temp;
	float wind_speed;
	float relat_humid;
	
	
	
	init {
		do startR;
		
		fuel_humid <- R_eval("1 - pnorm(" + to_R_data(raw_fuel_humid) + ", 100, 75) * 2");
		
		write fuel_humid;
	}
}



experiment wildfiresim	type:gui {
	parameter "Combustible base"	var:fuel_base min:0.0 max:1.0 category:"Combustible";
	parameter "Contenido de humedad del combustible"	var:raw_fuel_humid	min:50.0 max:100.0 category:"Combustible";
	parameter "Factor de disminución de la combustión"	var:diminish_factor min:0.0 max:1.0 category:"Combustible";
	
	parameter "Temperatura"	var:raw_temp min:0.0 max:40.0 category:"Clima";
	parameter "Humedad relativa"	var:raw_relat_humid min:50.0 max:100.0 category:"Clima";
	parameter "Dirección del viento"	var:wind_direction category:"Clima";
	parameter "Velocidad del viento"	var:raw_wind_speed min:0.0 max:50.0 category:"Clima";
}
