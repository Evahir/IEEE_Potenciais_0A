%% IEEE Std 80-2013 - Clausula 16.5 - Calculo das tensoes de malha e passo
%% (Mesh voltage Em e Step voltage Es - metodo simplificado de Sverak)
%% ========================================================================
%% Aplicado as equacoes (85) a (99) da IEEE Std 80-2013 para calcular Em e 
%% Es, comparando com os limites permissiveis de toque e passo.
%% -----------------------------------------------------------------------
%% 1) Determinação de parâmetros iniciais
%% -----------------------------------------------------------------------
If = 12.5;               % Corrente de falta fase-terra, kA
t  = 0.3;                 % Tempo de atuacao do sistema de protecao, s

Df = 1.085;               % Fator de decremento
Sf = 0.8;                 % Fator de distribuicao

IG_kA = Df*Sf*If;         % Corrente de malha (eq. 15.1-15.10 area), kA
IG = IG_kA*1000;          % Convertida para A - usada nas eq. (85) e (97)
fprintf('Corrente de malha (IG) = %.4f kA = %.1f A\n', IG_kA, IG);

rho_s = 3000;              % Resistividade da camada superficial (brita), ohm.m
rho_1 = 700;                % Resistividade da 1a camada de solo, ohm.m
rho_2 = 171.4597;           % Resistividade da 2a camada de solo, ohm.m

a2 = 1-(rho_1/rho_s);
a3 = 2*0.1+0.09;            % Eq. (27) IEEE: coeficiente 0,09
C  = 1 - 0.09*(a2/a3);      % Fator de reducao Cs

Ib50 = 0.116/sqrt(t);
Ib70 = 0.157/sqrt(t);

Valor_permissivel_toque_50kg = (1000 + 1.5*C*rho_s)*Ib50;   % Eq (32)
Valor_permissivel_toque_70kg = (1000 + 1.5*C*rho_s)*Ib70;   % Eq (33)
Valor_permissivel_passo_50kg = (1000 + 6*C*rho_s)*Ib50;     % Eq (29)-analoga
Valor_permissivel_passo_70kg = (1000 + 6*C*rho_s)*Ib70;
fprintf('Toque permissivel: 50kg = %.1f V | 70kg = %.1f V\n', Valor_permissivel_toque_50kg, Valor_permissivel_toque_70kg);
fprintf('Passo permissivel: 50kg = %.1f V | 70kg = %.1f V\n', Valor_permissivel_passo_50kg, Valor_permissivel_passo_70kg);

%% -----------------------------------------------------------------------
%% 2) Resistividade equivalente uniforme (Clausula 13.4.1)
%% -----------------------------------------------------------------------
% As equacoes de Em e Es (16.5) assumem SOLO UNIFORME (um unico rho).
% A norma remete a 13.4.1 para obter um rho equivalente para solo de
% duas camadas: nao ha a mesma regra explicita do Anexo B da NBR
% (usar rho_1 se rho_2<rho_1); a IEEE recomenda usar uma resistividade
% "aparente" equivalente (a mesma logica do rho_a ja calculado pelo
% metodo de Sverak/Anexo A da NBR, que reflete bem esse principio).
rho_eq = 329.333;   % rho_a, ja calculado na 1a etapa (resistencia de aterramento)
fprintf('Resistividade equivalente uniforme usada em Em/Es = %.3f ohm.m\n', rho_eq);

%% -----------------------------------------------------------------------
%% 3) Geometria real da malha (extraida do DXF do AutoCAD)
%% -----------------------------------------------------------------------
Lc = 11241.416;          % Comprimento total dos condutores horizontais, m (DXF)
Lp = 900.0;               % Comprimento do perimetro da malha, m (DXF - polyline fechada)
Lx = 300.0;                % Dimensao maxima em x, m
Ly = 150.0;                % Dimensao maxima em y, m
A  = Lx*Ly;                 % Area da malha, m2

nR = 48;                    % Numero de hastes
Lr = 3.0;                   % Comprimento de cada haste, m
LR = nR*Lr;                 % Comprimento total das hastes, m

H = 0.6;                    % Profundidade da malha, m
Secao_utilizada_mm2 = 35;   % Secao nominal escolhida na 1a etapa, mm2
d = sqrt(4*(Secao_utilizada_mm2*1e-6)/pi);  % Diametro do condutor, m
fprintf('Diametro do condutor (secao %d mm2) = %.4f mm\n', Secao_utilizada_mm2, d*1000);

%% -----------------------------------------------------------------------
%% 4) Fator geometrico n (eq. 89-93) - malha retangular
%% -----------------------------------------------------------------------
na = 2*Lc/Lp;                      % Eq (90)
nb = sqrt(Lp/(4*sqrt(A)));         % Eq (91)
nc = 1;                             % Eq (92): =1 para malha retangular
nd = 1;                             % Eq (93): =1 para malha retangular/quadrada/L
n = na*nb*nc*nd;                    % Eq (89)
fprintf('na=%.4f nb=%.4f nc=%.1f nd=%.1f -> n = %.4f\n', na, nb, nc, nd, n);

Ki = 0.644 + 0.148*n;              % Eq (94)
fprintf('Ki = %.4f\n', Ki);

%% -----------------------------------------------------------------------
%% 5) Fator Kii - hastes na periferia?
%% -----------------------------------------------------------------------
% Kii = 1 para malhas com hastes nos cantos, na periferia, e tambem ao
% longo de toda a malha (Eq. 87 caso contrario). Conferido via DXF:
% 26 das 48 hastes estao na periferia (incluindo cantos) e 22 sao
% internas -> exatamente o caso "corners + perimeter + throughout" -> Kii=1
hastes_com_periferia = true;
if hastes_com_periferia
    Kii = 1;
else
    Kii = 1/((2*n)^(2/n));          % Eq (87)
end
fprintf('Kii = %.4f\n', Kii);

h0 = 1.0;                            % Profundidade de referencia, m
Kh = sqrt(1 + H/h0);                 % Eq (88)
fprintf('Kh = %.4f\n', Kh);

%% -----------------------------------------------------------------------
%% 6) Comprimentos efetivos enterrados LM (Em) e Ls (Es)
%% -----------------------------------------------------------------------
% Eq (96): hastes nos cantos, na periferia e ao longo de toda a malha
LM = Lc + LR*(1.55 + 1.22*(Lr/sqrt(Lx^2+Ly^2)));   % Eq (96)
Ls = 0.75*Lc + 0.85*LR;                              % Eq (98)
fprintf('LM = %.3f m   Ls = %.3f m\n', LM, Ls);

%% -----------------------------------------------------------------------
%% 7) Calculo de Km, Ks, Em e Es nas duas direcoes da malha
%%    (Eq. 86, 99 - o metodo simplificado assume espacamento uniforme;
%%     como a malha tem D=6,25m e D=12,5m, calcula-se nas duas direcoes
%%     e adota-se o pior caso, na mesma logica aplicada ao script NBR)
%% -----------------------------------------------------------------------
D = [6.25, 12.5];

Em = zeros(1,2);
Es = zeros(1,2);
Km = zeros(1,2);
Ks = zeros(1,2);

for k = 1:2
    Dk = D(k);

    Km(k) = (1/(2*pi)) * ( ...
                log( (Dk^2)/(16*H*d) + ((Dk+2*H)^2)/(8*Dk*d) - H/(4*d) ) ...
                + (Kii/Kh) * log(8/(pi*(2*n-1))) );   % Eq (86)

    Ks(k) = (1/pi) * ( 1/(2*H) + 1/(Dk+H) + (1/Dk)*(1-0.5^(n-2)) );  % Eq (99)

    Em(k) = (rho_eq * Ki * Km(k) * IG) / LM;   % Eq (85)
    Es(k) = (rho_eq * Ki * Ks(k) * IG) / Ls;   % Eq (97)

    fprintf('\n--- Direcao %d (D = %.2f m) ---\n', k, Dk);
    fprintf('  Km = %.4f  ->  Em = %.2f V\n', Km(k), Em(k));
    fprintf('  Ks = %.4f  ->  Es = %.2f V\n', Ks(k), Es(k));
end

%% -----------------------------------------------------------------------
%% 8) Piores casos e comparacao com os limites permissiveis
%% -----------------------------------------------------------------------
[Em_max, idx_m] = max(Em);
[Es_max, idx_s] = max(Es);

fprintf('\n=========================================================\n');
fprintf('Tensao de malha (Em) calculada (pior caso, direcao %d) = %.2f V\n', idx_m, Em_max);
fprintf('Limite (Etouch50)  = %.2f V   |   Limite (Etouch70) = %.2f V\n', Valor_permissivel_toque_50kg, Valor_permissivel_toque_70kg);
if Em_max <= Valor_permissivel_toque_50kg
    fprintf('  -> OK: dentro do limite (inclusive para 50 kg)\n');
elseif Em_max <= Valor_permissivel_toque_70kg
    fprintf('  -> ATENCAO: excede o limite de 50 kg, mas fica dentro do limite de 70 kg\n');
else
    fprintf('  -> ATENCAO: Em calculado EXCEDE os limites permissiveis (50 kg e 70 kg)!\n');
end

fprintf('\nTensao de passo (Es) calculada (pior caso, direcao %d)  = %.2f V\n', idx_s, Es_max);
fprintf('Limite (Estep50) = %.2f V   |   Limite (Estep70) = %.2f V\n', Valor_permissivel_passo_50kg, Valor_permissivel_passo_70kg);
if Es_max <= Valor_permissivel_passo_50kg
    fprintf('  -> OK: dentro do limite (inclusive para 50 kg)\n');
else
    fprintf('  -> ATENCAO: Es calculado EXCEDE o limite permissivel!\n');
end
fprintf('=========================================================\n');
