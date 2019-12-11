select tipo_anomalia, lingua, dia_da_semana, count(*) from f_anomalia natural join d_lingua natural join d_tempo group by rollup(tipo_anomalia, lingua, dia_da_semana);
