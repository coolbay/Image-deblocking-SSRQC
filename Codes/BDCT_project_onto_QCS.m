function projectedImage  = BDCT_project_onto_QCS(I_hat, par)

C_q = par.C_q;
QTable = par.QTable;
Qfactor = par.Qfactor;
BlockSize = par.BlockSize;

fun_dct2 = @(block_struct) dct2(block_struct.data);
projectedCoe    = blockproc(I_hat, [BlockSize BlockSize], fun_dct2);        % initial value is DCT coefficients of restored image

maxRange   = Qfactor * QTable;         % use blockproc

fun_upper =  @(block_struct) (block_struct.data + maxRange);
fun_lower =  @(block_struct) (block_struct.data - maxRange);
upper      = blockproc(C_q, [BlockSize BlockSize], fun_upper);    
lower      = blockproc(C_q, [BlockSize BlockSize], fun_lower);

projectedCoe( projectedCoe>upper ) = upper( projectedCoe>upper );            % projection onto (N)QCS
projectedCoe( projectedCoe<lower ) = lower( projectedCoe<lower );

fun_idct2 = @(block_struct) idct2(block_struct.data);
projectedImage = blockproc(projectedCoe, [BlockSize BlockSize], fun_idct2);