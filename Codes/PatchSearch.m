function  INDX  =  PatchSearch(X, Row, Col, Off, Nv, S, I)

[N, M]   =   size(I);
Dim2     =   size(X,2);                    % patch size

% Searching range for the current block
rmin    =   max( Row-S, 1 );
rmax    =   min( Row+S, N );
cmin    =   max( Col-S, 1 );
cmax    =   min( Col+S, M );
         
idx     =   I(rmin:rmax, cmin:cmax);        % indices of all patches in the window
idx     =   idx(:);
B       =   X(idx, :);                      % all patches in the window
v       =   X(Off, :);                      % current patch
       
% Distance (MSE) between all patces in the window and the current patch
dis     =   (B(:,1) - v(1)).^2;             
for k = 2:Dim2
    dis   =  dis + (B(:,k) - v(k)).^2;
end
dis   =  dis./Dim2;

[~, ind]   =  sort(dis);                    % Sort all distances
INDX       =  idx( ind(1:Nv) );             % Pick the top Nv patches, return their indices

