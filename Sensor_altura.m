% CONFIGURACIÓN SERIAL
puerto = "COM6";
baudrate = 9600;
s = serialport(puerto, baudrate);
configureTerminator(s, "LF");
flush(s);

% MEDIDAS DEL VASO (forma de cono truncado)
H = 10;           % Altura del vaso (cm)
r1 = 4.25;        % Radio superior (boca)
r2 = 2.5;         % Radio inferior (base)
V_total = (1/3) * pi * H * (r1^2 + r2^2 + r1*r2);  % Volumen máximo

altura_sensor = 17.8;  % Altura del sensor

ti = datetime('now');
datosCSV = {};
datosCSV(1, :) = {'Tiempo (s)', 'M1', 'M2', 'M3', 'M4', 'M5', ...
                 'Promedio', 'Altura', 'Volumen', '% Llenado'};

% GRAFICAS
f = figure('Name','Agua llenando vaso','Position',[100,100,800,700]);
subplot(3,1,1); h1 = animatedline('Color','b','LineWidth',2);
xlabel('Tiempo (s)'); ylabel('Altura (cm)');
title('Altura promedio del agua'); grid on;

subplot(3,1,2); h2 = animatedline('Color','r','LineWidth',2);
xlabel('Tiempo (s)'); ylabel('Volumen (cm³)');
title('Volumen estimado de agua'); grid on;

subplot(3,1,3); h3 = animatedline('Color','g','LineWidth',2);
xlabel('Tiempo (s)'); ylabel('% Llenado');
title('Porcentaje del volumen total'); grid on;

% TOMA DE DATOS EN TIEMPO REAL
while true
    try
        linea = readline(s);

        if strlength(strtrim(linea)) == 0
            warning("Línea vacía recibida. Saltando...");
            continue;
        end

        partes = split(strtrim(linea), ',');
        if numel(partes) ~= 5
            warning("Se esperaban 5 valores, se recibieron %d. Saltando...", numel(partes));
            continue;
        end

        valores = str2double(partes);
        if any(isnan(valores))
            warning("Valores no numéricos. Saltando...");
            continue;
        end

        promedio = mean(valores);
        altura_arena = max(0, altura_sensor - promedio);
        r_actual = r2 + (r1 - r2) * (altura_arena / H);
        volumen = (1/3) * pi * altura_arena * (r_actual^2 + r2^2 + r_actual*r2);
        porcentaje = (volumen / V_total) * 100;
        t_actual = seconds(datetime('now') - ti);

        % Graficar en tiempo real
        addpoints(h1, t_actual, altura_arena);
        addpoints(h2, t_actual, volumen);
        addpoints(h3, t_actual, porcentaje);
        drawnow;

        % Crear fila y guardar en datosCSV
        fila = [ {t_actual}, num2cell(valores(:)'), {promedio, altura_arena, volumen, porcentaje} ];
        if size(fila,2) ~= 10
            warning('Fila inválida, no tiene 10 columnas. Saltando...');
            continue;
        end
        datosCSV(end+1, :) = fila;

        if promedio <= 2
            disp('📏 Agua ha llegado al tope (distancia promedio <= 2 cm).');
            break;
        end
    catch ME
        warning("⚠️ Error al leer: %s", ME.message);
        continue;
    end
end

% GUARDAR ARCHIVOS
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
archivoCSV = ['datos_agua_' timestamp '.csv'];
archivoPNG = ['grafica_agua_' timestamp '.png'];

% Ruta completa
fullCSV = fullfile(pwd, archivoCSV);
fullPNG = fullfile(pwd, archivoPNG);

try
    writecell(datosCSV, fullCSV);
    disp(['✔ CSV guardado en: ' fullCSV]);
catch ME
    disp('❌ Error al guardar CSV:');
    disp(getReport(ME));
end

try
    saveas(f, fullPNG);
    disp(['🖼️ Imagen guardada en: ' fullPNG]);
catch ME
    disp('❌ Error al guardar imagen:');
    disp(getReport(ME));
end

