function dfdy=dfdy2(f,y,periodic)
Dy=y(2,1)-y(1,1);
[ny,~]=size(f);
v=ones(ny,1);
    if periodic==0
        %2nd-order central difference
        A=1*spdiags(v,-1,ny,ny)-2*spdiags(v,0,ny,ny)+1*spdiags(v,1,ny,ny);
        %2nd-order forward difference
        A(1,1:4)=[2, -5, 4, -1];
        %2nd-order backward difference
        A(ny,ny-3:ny)=fliplr(A(1,1:4));
        A=A/(Dy^2);
        dfdy=A*f;

    elseif periodic==1
        %4th-order central difference
        ny=ny-1;
        A=-1*spdiags(v,-2,ny,ny)+16*spdiags(v,-1,ny,ny)-30*spdiags(v,0,ny,ny)+16*spdiags(v,1,ny,ny)-1*spdiags(v,2,ny,ny);
        A(1,ny-1)=-1; A(1,ny)=16; 
        A(2,ny)=-1;
        A(ny,1)=16;  A(ny,2)=-1;  
        A(ny-1,1)=-1;
        A=A/(12*Dy^2);
        dfdy=A*f(1:(end-1),:);
        dfdy=[dfdy;dfdy(1,:)];
    end
end