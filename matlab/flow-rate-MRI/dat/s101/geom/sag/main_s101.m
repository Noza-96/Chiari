fname = 'IM-0066-0004.dcm';

I = dicomread(fname);
info = dicominfo(fname);

fcalvec = info.PixelSpacing;

fcal = fcalvec(1)

I = imadjust(uint8(255*double(I)/(1.00*double(max(I(:))))));

imwrite(I, 'spine_composing.tif');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp("Click on the basion (anterior)")
figure(101)
imshow(I, 'InitialMagnification', 400)
[xBASION, zBASION] = ginputc(1, 'Color', 'r', 'LineWidth', 1, 'ShowPoints', true);
figure(101)
hold on
plot(xBASION, zBASION, 'mo', 'MarkerFaceColor', 'm')

disp("and then on the opisthion (posterior).")
[xOPISTH, zOPISTH] = ginputc(1, 'Color', 'r', 'LineWidth', 1, 'ShowPoints', true);
figure(101)
hold on
plot(xOPISTH, zOPISTH, 'mo', 'MarkerFaceColor', 'm')
hold on
plot([xBASION, xOPISTH], [zBASION, zOPISTH], 'm-', 'LineWidth', 2)

disp('Click on the center of the spinal cord along the McRae line.')
[xFORMAG, zFORMAG] = ginputc(1, 'Color', 'r', 'LineWidth', 1, 'ShowPoints', true);
figure(101)
hold on
plot(xFORMAG, zFORMAG, 'mo', 'MarkerFaceColor', 'm')

disp("Click on the center of the anterior arch of atlas (C1)")
[xAATLAS, zAATLAS] = ginputc(1, 'Color', 'r', 'LineWidth', 1, 'ShowPoints', true);
figure(101)
hold on
plot(xAATLAS, zAATLAS, 'mo', 'MarkerFaceColor', 'm')

disp("and then on center of the posterior arch of atlas (C1).")
[xPATLAS, zPATLAS] = ginputc(1, 'Color', 'r', 'LineWidth', 1, 'ShowPoints', true);
figure(101)
hold on
plot(xPATLAS, zPATLAS, 'mo', 'MarkerFaceColor', 'm')
hold on
plot([xAATLAS, xPATLAS], [zAATLAS, zPATLAS], 'm-', 'LineWidth', 2)

disp('Click on the center of the spinal cord along the atlas line.')
[xC01, zC01] = ginputc(1, 'Color', 'r', 'LineWidth', 1, 'ShowPoints', true);
figure(101)
hold on
plot(xC01, zC01, 'mo', 'MarkerFaceColor', 'm')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% We also name the foramen magnum as C00

xC00 = xFORMAG;
zC00 = zFORMAG;

disp('Click on the center of the spinal cord at the cervical vertebral discs,')
disp('starting with C02/C03 and ending with C07/T01.')

[xD_cer, zD_cer] = ginputc(6, 'Color', 'r', 'LineWidth', 1, 'ShowPoints', true);
figure(101)
hold on
plot(xD_cer, zD_cer, 'ms', 'MarkerFaceColor', 'm')

xC02C03 = xD_cer(1);
xC03C04 = xD_cer(2);
xC04C05 = xD_cer(3);
xC05C06 = xD_cer(4);
xC06C07 = xD_cer(5);
xC07T01 = xD_cer(6);

zC02C03 = zD_cer(1);
zC03C04 = zD_cer(2);
zC04C05 = zD_cer(3);
zC05C06 = zD_cer(4);
zC06C07 = zD_cer(5);
zC07T01 = zD_cer(6);

disp('Click on the center of spinal cord at the thoracic vertebral discs,')
disp('starting with T01/T02 and ending with T12/L01.')

[xD_tho, zD_tho] = ginputc(12, 'Color', 'r', 'LineWidth', 1, 'ShowPoints', true);
figure(101)
hold on
plot(xD_tho, zD_tho, 'mv', 'MarkerFaceColor', 'm')

xT01T02 = xD_tho( 1);
xT02T03 = xD_tho( 2);
xT03T04 = xD_tho( 3);
xT04T05 = xD_tho( 4);
xT05T06 = xD_tho( 5);
xT06T07 = xD_tho( 6);
xT07T08 = xD_tho( 7);
xT08T09 = xD_tho( 8);
xT09T10 = xD_tho( 9);
xT10T11 = xD_tho(10);
xT11T12 = xD_tho(11);
xT12L01 = xD_tho(12);

zT01T02 = zD_tho( 1);
zT02T03 = zD_tho( 2);
zT03T04 = zD_tho( 3);
zT04T05 = zD_tho( 4);
zT05T06 = zD_tho( 5);
zT06T07 = zD_tho( 6);
zT07T08 = zD_tho( 7);
zT08T09 = zD_tho( 8);
zT09T10 = zD_tho( 9);
zT10T11 = zD_tho(10);
zT11T12 = zD_tho(11);
zT12L01 = zD_tho(12);

disp('Click on the center of the spinal cord at the lumbar vertebral discs,')
disp('starting with L01/L02 and ending with L05/S01.')

[xD_lum, zD_lum] = ginputc(5, 'Color', 'r', 'LineWidth', 1, 'ShowPoints', true);
figure(101)
hold on
plot(xD_lum, zD_lum, 'm^', 'MarkerFaceColor', 'm')

xL01L02 = xD_lum(1);
xL02L03 = xD_lum(2);
xL03L04 = xD_lum(3);
xL04L05 = xD_lum(4);
xL05S01 = xD_lum(5);

zL01L02 = zD_lum(1);
zL02L03 = zD_lum(2);
zL03L04 = zD_lum(3);
zL04L05 = zD_lum(4);
zL05S01 = zD_lum(5);

disp('Click on the center of the spinal cord at the sacral vertebral discs,')
disp('starting with S01/S02 and ending with S03/S04.')

[xD_sac, zD_sac] = ginputc(3, 'Color', 'r', 'LineWidth', 1, 'ShowPoints', true);
figure(101)
hold on
plot(xD_sac, zD_sac, 'md', 'MarkerFaceColor', 'm')

xS01S02 = xD_sac(1);
xS02S03 = xD_sac(2);
xS03S04 = xD_sac(3);

zS01S02 = zD_sac(1);
zS02S03 = zD_sac(2);
zS03S04 = zD_sac(3);

save('1_marked.mat');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% We put all of them together:

xD = [xD_cer; xD_tho; xD_lum; xD_sac];
zD = [zD_cer; zD_tho; zD_lum; zD_sac];

figure(102)
imshow(I, 'InitialMagnification', 300)
hold on
plot([xBASION, xOPISTH], [zBASION, zOPISTH], 'm-', 'LineWidth', 2)
plot([xAATLAS, xPATLAS], [zAATLAS, zPATLAS], 'm-', 'LineWidth', 2)
plot(xC00, zC00, 'm+')
plot(xC01, zC01, 'm+')
plot(xD_cer, zD_cer, 'm+')
plot(xD_tho, zD_tho, 'm+')
plot(xD_lum, zD_lum, 'm+')
plot(xD_sac, zD_sac, 'm+')
plot(xD , zD , 'co-')
axis on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Now we compute the location of the vertebrae:

xC02 = 0.5 * (xC01    + xC02C03);
xC03 = 0.5 * (xC02C03 + xC03C04);
xC04 = 0.5 * (xC03C04 + xC04C05);
xC05 = 0.5 * (xC04C05 + xC05C06);
xC06 = 0.5 * (xC05C06 + xC06C07);
xC07 = 0.5 * (xC06C07 + xC07T01);
xT01 = 0.5 * (xC07T01 + xT01T02);
xT02 = 0.5 * (xT01T02 + xT02T03);
xT03 = 0.5 * (xT02T03 + xT03T04);
xT04 = 0.5 * (xT03T04 + xT04T05);
xT05 = 0.5 * (xT04T05 + xT05T06);
xT06 = 0.5 * (xT05T06 + xT06T07);
xT07 = 0.5 * (xT06T07 + xT07T08);
xT08 = 0.5 * (xT07T08 + xT08T09);
xT09 = 0.5 * (xT08T09 + xT09T10);
xT10 = 0.5 * (xT09T10 + xT10T11);
xT11 = 0.5 * (xT10T11 + xT11T12);
xT12 = 0.5 * (xT11T12 + xT12L01);
xL01 = 0.5 * (xT12L01 + xL01L02);
xL02 = 0.5 * (xL01L02 + xL02L03);
xL03 = 0.5 * (xL02L03 + xL03L04);
xL04 = 0.5 * (xL03L04 + xL04L05);
xL05 = 0.5 * (xL04L05 + xL05S01);
xS01 = 0.5 * (xL05S01 + xS01S02);
xS02 = 0.5 * (xS01S02 + xS02S03);
xS03 = 0.5 * (xS02S03 + xS03S04);

zC02 = 0.5 * (zC01    + zC02C03);
zC03 = 0.5 * (zC02C03 + zC03C04);
zC04 = 0.5 * (zC03C04 + zC04C05);
zC05 = 0.5 * (zC04C05 + zC05C06);
zC06 = 0.5 * (zC05C06 + zC06C07);
zC07 = 0.5 * (zC06C07 + zC07T01);
zT01 = 0.5 * (zC07T01 + zT01T02);
zT02 = 0.5 * (zT01T02 + zT02T03);
zT03 = 0.5 * (zT02T03 + zT03T04);
zT04 = 0.5 * (zT03T04 + zT04T05);
zT05 = 0.5 * (zT04T05 + zT05T06);
zT06 = 0.5 * (zT05T06 + zT06T07);
zT07 = 0.5 * (zT06T07 + zT07T08);
zT08 = 0.5 * (zT07T08 + zT08T09);
zT09 = 0.5 * (zT08T09 + zT09T10);
zT10 = 0.5 * (zT09T10 + zT10T11);
zT11 = 0.5 * (zT10T11 + zT11T12);
zT12 = 0.5 * (zT11T12 + zT12L01);
zL01 = 0.5 * (zT12L01 + zL01L02);
zL02 = 0.5 * (zL01L02 + zL02L03);
zL03 = 0.5 * (zL02L03 + zL03L04);
zL04 = 0.5 * (zL03L04 + zL04L05);
zL05 = 0.5 * (zL04L05 + zL05S01);
zS01 = 0.5 * (zL05S01 + zS01S02);
zS02 = 0.5 * (zS01S02 + zS02S03);
zS03 = 0.5 * (zS02S03 + zS03S04);

xV_cer = [ xC00; xC01; xC02; xC03; xC04; xC05; xC06; xC07 ];
xV_tho = [ xT01; xT02; xT03; xT04; xT05; xT06; xT07; xT08; xT09; xT10; xT11; xT12 ];
xV_lum = [ xL01; xL02; xL03; xL04; xL05 ];
xV_sac = [ xS01; xS02; xS03 ];
xV = [ xV_cer; xV_tho; xV_lum; xV_sac ];

zV_cer = [ zC00; zC01; zC02; zC03; zC04; zC05; zC06; zC07 ];
zV_tho = [ zT01; zT02; zT03; zT04; zT05; zT06; zT07; zT08; zT09; zT10; zT11; zT12 ];
zV_lum = [ zL01; zL02; zL03; zL04; zL05 ];
zV_sac = [ zS01; zS02; zS03 ];
zV = [ zV_cer; zV_tho; zV_lum; zV_sac ];

save('1_marked.mat');

V_label = { ...
    'C00', 'C01', 'C02', 'C03', 'C04', 'C05', 'C06', 'C07', ...
    'T01', 'T02', 'T03', 'T04', 'T05', 'T06', 'T07', 'T08', 'T09', 'T10', 'T11', 'T12', ...
    'L01', 'L02', 'L03', 'L04', 'L05', ...
    'S01', 'S02', 'S03', ...
    };

D_label = { ...
    'C02C03', 'C03C04', 'C04C05', 'C05C06', 'C06C07', 'C07T01', ...
    'T01T02', 'T02T03', 'T03T04', 'T04T05', 'T05T06', 'T06T07', 'T07T08', 'T08T09', 'T09T10', 'T10T11', 'T11T12', 'T12L01', ...
    'L01L02', 'L02L03', 'L03L04', 'L04L05', 'L05S01', ...
    'S01S02', 'S02S03', 'S03S04', ...
    };

figure(104)
imshow(I, 'InitialMagnification', 300)
hold on
plot(xV_cer, zV_cer, 'ms')
plot(xV_tho, zV_tho, 'm^')
plot(xV_lum, zV_lum, 'mv')
plot(xV_sac, zV_sac, 'md')
plot(xD, zD, 'k+-')
plot(xV, zV, 'yo')
axis on
drawnow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

kleur1 = rgb('Salmon');
kleur2 = rgb('SkyBlue');

figure(110)
imshow(I, 'InitialMagnification', 300)
hold on
for k = 1:length(xV)
    plot(xV(k), zV(k), 'o', 'Color', kleur1, 'MarkerFaceColor', kleur1)
    text(xV(k)+10, zV(k), V_label{k}, 'Color', kleur1, 'FontWeight', 'bold', 'BackgroundColor', 'k', 'EdgeColor', 'none', 'Margin', 0.1)
end
for k = 1:length(xD)
    plot(xD(k), zD(k), 'o', 'Color', kleur2, 'MarkerFaceColor', kleur2)
    text(xD(k)+10, zD(k), D_label{k}, 'Color', kleur2, 'FontWeight', 'bold', 'BackgroundColor', 'k', 'EdgeColor', 'none', 'Margin', 0.1)
end
set(gcf, 'Position', [100, 0, 800, 1300])
drawnow
savefig('anatomy_image.fig')
fig = gcf;
fig.PaperPositionMode = 'auto';
print('anatomy_image.png', '-dpng','-r300')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%We convert positions to lengths in cm

fcal = 0.1*fcal; % to get cm!

xlC00    = fcal * xC00;
zlC00    = fcal * zC00;

xlC01    = fcal * xC01    - xlC00;
xlC02    = fcal * xC02    - xlC00;
xlC03    = fcal * xC03    - xlC00;
xlC04    = fcal * xC04    - xlC00;
xlC05    = fcal * xC05    - xlC00;
xlC06    = fcal * xC06    - xlC00;
xlC07    = fcal * xC07    - xlC00;
xlT01    = fcal * xT01    - xlC00;
xlT02    = fcal * xT02    - xlC00;
xlT03    = fcal * xT03    - xlC00;
xlT04    = fcal * xT04    - xlC00;
xlT05    = fcal * xT05    - xlC00;
xlT06    = fcal * xT06    - xlC00;
xlT07    = fcal * xT07    - xlC00;
xlT08    = fcal * xT08    - xlC00;
xlT09    = fcal * xT09    - xlC00;
xlT10    = fcal * xT10    - xlC00;
xlT11    = fcal * xT11    - xlC00;
xlT12    = fcal * xT12    - xlC00;
xlL01    = fcal * xL01    - xlC00;
xlL02    = fcal * xL02    - xlC00;
xlL03    = fcal * xL03    - xlC00;
xlL04    = fcal * xL04    - xlC00;
xlL05    = fcal * xL05    - xlC00;
xlS01    = fcal * xS01    - xlC00;
xlS02    = fcal * xS02    - xlC00;
xlS03    = fcal * xS03    - xlC00;
xlC02C03 = fcal * xC02C03 - xlC00;
xlC03C04 = fcal * xC03C04 - xlC00;
xlC04C05 = fcal * xC04C05 - xlC00;
xlC05C06 = fcal * xC05C06 - xlC00;
xlC06C07 = fcal * xC06C07 - xlC00;
xlC07T01 = fcal * xC07T01 - xlC00;
xlT01T02 = fcal * xT01T02 - xlC00;
xlT02T03 = fcal * xT02T03 - xlC00;
xlT03T04 = fcal * xT03T04 - xlC00;
xlT04T05 = fcal * xT04T05 - xlC00;
xlT05T06 = fcal * xT05T06 - xlC00;
xlT06T07 = fcal * xT06T07 - xlC00;
xlT07T08 = fcal * xT07T08 - xlC00;
xlT08T09 = fcal * xT08T09 - xlC00;
xlT09T10 = fcal * xT09T10 - xlC00;
xlT10T11 = fcal * xT10T11 - xlC00;
xlT11T12 = fcal * xT11T12 - xlC00;
xlT12L01 = fcal * xT12L01 - xlC00;
xlL01L02 = fcal * xL01L02 - xlC00;
xlL02L03 = fcal * xL02L03 - xlC00;
xlL03L04 = fcal * xL03L04 - xlC00;
xlL04L05 = fcal * xL04L05 - xlC00;
xlL05S01 = fcal * xL05S01 - xlC00;
xlS01S02 = fcal * xS01S02 - xlC00;
xlS02S03 = fcal * xS02S03 - xlC00;
xlS03S04 = fcal * xS03S04 - xlC00;
xlD      = fcal * xD      - xlC00;
xlV      = fcal * xV      - xlC00;
xlBASION = fcal * xBASION - xlC00;
xlOPISTH = fcal * xOPISTH - xlC00;
xlFORMAG = fcal * xFORMAG - xlC00;
xlAATLAS = fcal * xAATLAS - xlC00;
xlPATLAS = fcal * xPATLAS - xlC00;

zlC01    = fcal * zC01    - zlC00;
zlC02    = fcal * zC02    - zlC00;
zlC03    = fcal * zC03    - zlC00;
zlC04    = fcal * zC04    - zlC00;
zlC05    = fcal * zC05    - zlC00;
zlC06    = fcal * zC06    - zlC00;
zlC07    = fcal * zC07    - zlC00;
zlT01    = fcal * zT01    - zlC00;
zlT02    = fcal * zT02    - zlC00;
zlT03    = fcal * zT03    - zlC00;
zlT04    = fcal * zT04    - zlC00;
zlT05    = fcal * zT05    - zlC00;
zlT06    = fcal * zT06    - zlC00;
zlT07    = fcal * zT07    - zlC00;
zlT08    = fcal * zT08    - zlC00;
zlT09    = fcal * zT09    - zlC00;
zlT10    = fcal * zT10    - zlC00;
zlT11    = fcal * zT11    - zlC00;
zlT12    = fcal * zT12    - zlC00;
zlL01    = fcal * zL01    - zlC00;
zlL02    = fcal * zL02    - zlC00;
zlL03    = fcal * zL03    - zlC00;
zlL04    = fcal * zL04    - zlC00;
zlL05    = fcal * zL05    - zlC00;
zlS01    = fcal * zS01    - zlC00;
zlS02    = fcal * zS02    - zlC00;
zlS03    = fcal * zS03    - zlC00;
zlC02C03 = fcal * zC02C03 - zlC00;
zlC03C04 = fcal * zC03C04 - zlC00;
zlC04C05 = fcal * zC04C05 - zlC00;
zlC05C06 = fcal * zC05C06 - zlC00;
zlC06C07 = fcal * zC06C07 - zlC00;
zlC07T01 = fcal * zC07T01 - zlC00;
zlT01T02 = fcal * zT01T02 - zlC00;
zlT02T03 = fcal * zT02T03 - zlC00;
zlT03T04 = fcal * zT03T04 - zlC00;
zlT04T05 = fcal * zT04T05 - zlC00;
zlT05T06 = fcal * zT05T06 - zlC00;
zlT06T07 = fcal * zT06T07 - zlC00;
zlT07T08 = fcal * zT07T08 - zlC00;
zlT08T09 = fcal * zT08T09 - zlC00;
zlT09T10 = fcal * zT09T10 - zlC00;
zlT10T11 = fcal * zT10T11 - zlC00;
zlT11T12 = fcal * zT11T12 - zlC00;
zlT12L01 = fcal * zT12L01 - zlC00;
zlL01L02 = fcal * zL01L02 - zlC00;
zlL02L03 = fcal * zL02L03 - zlC00;
zlL03L04 = fcal * zL03L04 - zlC00;
zlL04L05 = fcal * zL04L05 - zlC00;
zlL05S01 = fcal * zL05S01 - zlC00;
zlS01S02 = fcal * zS01S02 - zlC00;
zlS02S03 = fcal * zS02S03 - zlC00;
zlS03S04 = fcal * zS03S04 - zlC00;
zlD      = fcal * zD      - zlC00;
zlV      = fcal * zV      - zlC00;
zlBASION = fcal * zBASION - zlC00;
zlOPISTH = fcal * zOPISTH - zlC00;
zlFORMAG = fcal * zFORMAG - zlC00;
zlAATLAS = fcal * zAATLAS - zlC00;
zlPATLAS = fcal * zPATLAS - zlC00;

xlC00 = 0.0;
zlC00 = 0.0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set up an interpolator to compute the distance to FM:

xlVD = [xlV; xlD];
zlVD = [zlV; zlD];

[zlVD, ind] = sort(zlVD);
xlVD = xlVD(ind);

f = griddedInterpolant(zlVD, xlVD, 'makima');

zz = linspace(0, max(zlVD), 1001);
xx = f(zz);

figure(111)
hold on
plot(xx, zz, 'k.-');
plot(xlD, zlD, 'rx');
plot(xlV, zlV, 'bo');
set(gca,'Ydir', 'reverse')
axis equal
xlim([-10, 10])
ylim([-5, 70])
grid on
grid minor
set(gcf, 'Position', [100, 0, 800, 1300])
savefig('anatomy_lengths.fig')
fig = gcf;
fig.PaperPositionMode = 'auto';
print('anatomy_lengths.png', '-dpng','-r300')

% distances between points:

ss = sqrt(diff(xx).^2 + diff(zz).^2);

% distance along arc from FM:

dd = cumsum(ss);

% Finally, we set up an interpolator for this distance to FM:

fun_z2d = griddedInterpolant(zz(2:end), dd);

% We can use this interpolator to get the distance to FM of the corresponding
% discs and vertebrae:

dlD = fun_z2d(zlD);
dlV = fun_z2d(zlV);

figure(112)
hold on
plot(zeros(size(dlD)), dlD, 'kx')
plot(zeros(size(zlD)), zlD, 'gx')
set(gca, 'yDir', 'reverse')


% We put all the useful stuff in a structure named geomdata to use in the
% velocity data postprocessing:

geomdata.xC02C03 = xlD( 1);
geomdata.xC03C04 = xlD( 2);
geomdata.xC04C05 = xlD( 3);
geomdata.xC05C06 = xlD( 4);
geomdata.xC06C07 = xlD( 5);
geomdata.xC07T01 = xlD( 6);
geomdata.xT01T02 = xlD( 7);
geomdata.xT02T03 = xlD( 8);
geomdata.xT03T04 = xlD( 9);
geomdata.xT04T05 = xlD(10);
geomdata.xT05T06 = xlD(11);
geomdata.xT06T07 = xlD(12);
geomdata.xT07T08 = xlD(13);
geomdata.xT08T09 = xlD(14);
geomdata.xT09T10 = xlD(15);
geomdata.xT10T11 = xlD(16);
geomdata.xT11T12 = xlD(17);
geomdata.xT12L01 = xlD(18);
geomdata.xL01L02 = xlD(19);
geomdata.xL02L03 = xlD(20);
geomdata.xL03L04 = xlD(21);
geomdata.xL04L05 = xlD(22);
geomdata.xL05S01 = xlD(23);
geomdata.xS01S02 = xlD(24);
geomdata.xS02S03 = xlD(25);
geomdata.xS03S04 = xlD(26);

geomdata.zC02C03 = zlD( 1);
geomdata.zC03C04 = zlD( 2);
geomdata.zC04C05 = zlD( 3);
geomdata.zC05C06 = zlD( 4);
geomdata.zC06C07 = zlD( 5);
geomdata.zC07T01 = zlD( 6);
geomdata.zT01T02 = zlD( 7);
geomdata.zT02T03 = zlD( 8);
geomdata.zT03T04 = zlD( 9);
geomdata.zT04T05 = zlD(10);
geomdata.zT05T06 = zlD(11);
geomdata.zT06T07 = zlD(12);
geomdata.zT07T08 = zlD(13);
geomdata.zT08T09 = zlD(14);
geomdata.zT09T10 = zlD(15);
geomdata.zT10T11 = zlD(16);
geomdata.zT11T12 = zlD(17);
geomdata.zT12L01 = zlD(18);
geomdata.zL01L02 = zlD(19);
geomdata.zL02L03 = zlD(20);
geomdata.zL03L04 = zlD(21);
geomdata.zL04L05 = zlD(22);
geomdata.zL05S01 = zlD(23);
geomdata.zS01S02 = zlD(24);
geomdata.zS02S03 = zlD(25);
geomdata.zS03S04 = zlD(26);

geomdata.dC02C03 = dlD( 1);
geomdata.dC03C04 = dlD( 2);
geomdata.dC04C05 = dlD( 3);
geomdata.dC05C06 = dlD( 4);
geomdata.dC06C07 = dlD( 5);
geomdata.dC07T01 = dlD( 6);
geomdata.dT01T02 = dlD( 7);
geomdata.dT02T03 = dlD( 8);
geomdata.dT03T04 = dlD( 9);
geomdata.dT04T05 = dlD(10);
geomdata.dT05T06 = dlD(11);
geomdata.dT06T07 = dlD(12);
geomdata.dT07T08 = dlD(13);
geomdata.dT08T09 = dlD(14);
geomdata.dT09T10 = dlD(15);
geomdata.dT10T11 = dlD(16);
geomdata.dT11T12 = dlD(17);
geomdata.dT12L01 = dlD(18);
geomdata.dL01L02 = dlD(19);
geomdata.dL02L03 = dlD(20);
geomdata.dL03L04 = dlD(21);
geomdata.dL04L05 = dlD(22);
geomdata.dL05S01 = dlD(23);
geomdata.dS01S02 = dlD(24);
geomdata.dS02S03 = dlD(25);
geomdata.dS03S04 = dlD(26);

geomdata.xC00 = xlV( 1);
geomdata.xC01 = xlV( 2);
geomdata.xC02 = xlV( 3);
geomdata.xC03 = xlV( 4);
geomdata.xC04 = xlV( 5);
geomdata.xC05 = xlV( 6);
geomdata.xC06 = xlV( 7);
geomdata.xC07 = xlV( 8);
geomdata.xT01 = xlV( 9);
geomdata.xT02 = xlV(10);
geomdata.xT03 = xlV(11);
geomdata.xT04 = xlV(12);
geomdata.xT05 = xlV(13);
geomdata.xT06 = xlV(14);
geomdata.xT07 = xlV(15);
geomdata.xT08 = xlV(16);
geomdata.xT09 = xlV(17);
geomdata.xT10 = xlV(18);
geomdata.xT11 = xlV(19);
geomdata.xT12 = xlV(20);
geomdata.xL01 = xlV(21);
geomdata.xL02 = xlV(22);
geomdata.xL03 = xlV(23);
geomdata.xL04 = xlV(24);
geomdata.xL05 = xlV(25);
geomdata.xS01 = xlV(26);
geomdata.xS02 = xlV(27);
geomdata.xS03 = xlV(28);

geomdata.zC00 = zlV( 1);
geomdata.zC01 = zlV( 2);
geomdata.zC02 = zlV( 3);
geomdata.zC03 = zlV( 4);
geomdata.zC04 = zlV( 5);
geomdata.zC05 = zlV( 6);
geomdata.zC06 = zlV( 7);
geomdata.zC07 = zlV( 8);
geomdata.zT01 = zlV( 9);
geomdata.zT02 = zlV(10);
geomdata.zT03 = zlV(11);
geomdata.zT04 = zlV(12);
geomdata.zT05 = zlV(13);
geomdata.zT06 = zlV(14);
geomdata.zT07 = zlV(15);
geomdata.zT08 = zlV(16);
geomdata.zT09 = zlV(17);
geomdata.zT10 = zlV(18);
geomdata.zT11 = zlV(19);
geomdata.zT12 = zlV(20);
geomdata.zL01 = zlV(21);
geomdata.zL02 = zlV(22);
geomdata.zL03 = zlV(23);
geomdata.zL04 = zlV(24);
geomdata.zL05 = zlV(25);
geomdata.zS01 = zlV(26);
geomdata.zS02 = zlV(27);
geomdata.zS03 = zlV(28);

geomdata.dC00 = dlV( 1);
geomdata.dC01 = dlV( 2);
geomdata.dC02 = dlV( 3);
geomdata.dC03 = dlV( 4);
geomdata.dC04 = dlV( 5);
geomdata.dC05 = dlV( 6);
geomdata.dC06 = dlV( 7);
geomdata.dC07 = dlV( 8);
geomdata.dT01 = dlV( 9);
geomdata.dT02 = dlV(10);
geomdata.dT03 = dlV(11);
geomdata.dT04 = dlV(12);
geomdata.dT05 = dlV(13);
geomdata.dT06 = dlV(14);
geomdata.dT07 = dlV(15);
geomdata.dT08 = dlV(16);
geomdata.dT09 = dlV(17);
geomdata.dT10 = dlV(18);
geomdata.dT11 = dlV(19);
geomdata.dT12 = dlV(20);
geomdata.dL01 = dlV(21);
geomdata.dL02 = dlV(22);
geomdata.dL03 = dlV(23);
geomdata.dL04 = dlV(24);
geomdata.dL05 = dlV(25);
geomdata.dS01 = dlV(26);
geomdata.dS02 = dlV(27);
geomdata.dS03 = dlV(28);

geomdata.xBASION = xlBASION;
geomdata.xOPISTH = xlOPISTH;
geomdata.xFORMAG = xlFORMAG;
geomdata.xAATLAS = xlAATLAS;
geomdata.xPATLAS = xlPATLAS;

geomdata.zBASION = zlBASION;
geomdata.zOPISTH = zlOPISTH;
geomdata.zFORMAG = zlFORMAG;
geomdata.zAATLAS = zlAATLAS;
geomdata.zPATLAS = xlPATLAS;

geomdata.dBASION = fun_z2d(zlBASION);
geomdata.dOPISTH = fun_z2d(zlOPISTH);
geomdata.dFORMAG = fun_z2d(zlFORMAG);
geomdata.dAATLAS = fun_z2d(zlAATLAS);
geomdata.dPATLAS = fun_z2d(zlPATLAS);

geomdata.convert_z2d = fun_z2d;

save('geomdata.mat', 'geomdata');

save('all.mat');

system('find . -iname "*.png" -exec mogrify -trim {} \;');