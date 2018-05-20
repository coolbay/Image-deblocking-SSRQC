function [ImgRec] = Dict_learning(ImgInput, par, v)

%% Load paramters
PatchSize = par.PatchSize;
PatchSize2 = PatchSize*PatchSize;
SlidingDis = par.SlidingDis ;
ArrayNo = par.ArrayNo;
Factor = par.Factor;
SearchWin = par.SearchWin;

% Threshold = sqrt(2*tau)               ...... Eq. (37) for threshold
% = sqrt(2*lambda*beta*K)/N             ...... below Eq. (36) for tau
% = (sqrt(2*lambda*K)/N)*sqrt(rho)*sigma_s  ...... Eq. (28) for beta
% sigma_s: v; (sqrt(2*lambda*K)/N)*sqrt(rho): Factor
Threshold = Factor * v;

%% Prepare all blocks to model
[Hight, Width] = size(ImgInput);
N = Hight-PatchSize+1;
M = Width-PatchSize+1;

L = N*M;
I = (1:L);
I = reshape(I, N, M);          % Indices of all patches

Row = 1:SlidingDis:N;          % row indices for all pathces-to-model
Row = [Row Row(end)+1:N];
Col = 1:SlidingDis:M;          % column indeces for all patches-to-model
Col = [Col Col(end)+1:M];
NN = length(Row);              % no. of patch per column
MM = length(Col);              % no. of patch per row

%% Extract all patches in ImgInput into PatchSet for group candidates
% PatchSet. i-th column: i-th patch; i-th row: i-th pixel in all pathces
PatchSet     =  zeros(PatchSize2, L, 'single');
Count     =  0;                % the count-th pixel in each patch
for i  = 1:PatchSize
    for j  = 1:PatchSize
        Count    =  Count+1;
        Patch  =  ImgInput(i:Hight-PatchSize+i,j:Width-PatchSize+j);
        Patch  =  Patch(:);
        PatchSet(Count,:) =  Patch';
    end
end
% PatchSetT: row-one block, column-corresponding  pixels in all patches
PatchSetT  =   PatchSet';
NewPatchSet = zeros(size(PatchSet));
NewWeight = zeros(size(PatchSet));


%% Model and reconstruct each path
for  i = 1 : NN                   % for the i-th patch in one column
    for  j = 1 : MM               % for the j-th patch in one row
        %(CurRow, CurCol): corrdinate of the current patch
        CurRow = Row(i);     % row index of the current patch
        CurCol = Col(j);     % column index of the current patch
        Off = (CurCol-1)*N + CurRow;    % order from top to bottom, then left to right
        
        % Indices of similar patches to the current patch
        CurPatchIndx  =  PatchSearch(PatchSetT, CurRow, CurCol, Off, ArrayNo, SearchWin, I);
        CurPatchIndx(1) = Off;                      % force the first similar patch to be the current patch itselft
        CurArray = PatchSet(:, CurPatchIndx);       % pixel values of the similar patches, the matrix X_G_k
        
        [SG_S, SG_V, SG_D] = svd(CurArray);         % SVD for the matrix X_G_k
        
        SG_Z = SG_V .* (abs(SG_V) > Threshold);     % Eq. (37), hard thresholding the singlular values
        CurArray = SG_S * SG_Z * SG_D';             % Reconstruct the group using the thresholded singlular values
        
        % Store the updated value of all patches in the group
        NewPatchSet(:, CurPatchIndx) = NewPatchSet(:, CurPatchIndx) + CurArray;
        % NewWeight signifies one occurance in a position for weighted average 
        NewWeight(:, CurPatchIndx) = NewWeight(:, CurPatchIndx) + 1;
    end
end

%% Put all patches back into the image
Count = 0;
ImgTemp  = zeros(Hight, Width);
ImgWeight = zeros(Hight, Width);
for i = 1 : PatchSize
    for j = 1 : PatchSize
        Count = Count+1;
        ImgTemp(i:Hight-PatchSize+i,j:Width-PatchSize+j) = ImgTemp(i:Hight-PatchSize+i,j:Width-PatchSize+j) + col2im(NewPatchSet(Count,:), [PatchSize PatchSize],[Hight Width], 'sliding');
        ImgWeight(i:Hight-PatchSize+i,j:Width-PatchSize+j) = ImgWeight(i:Hight-PatchSize+i,j:Width-PatchSize+j) + col2im(NewWeight(Count,:), [PatchSize PatchSize],[Hight Width], 'sliding');
        
    end
end

ImgRec = ImgTemp./(ImgWeight+eps);





