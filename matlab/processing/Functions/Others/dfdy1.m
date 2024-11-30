function dfdy=dfdy1(f,y,periodic)
Dy=y(2,1)-y(1,1);
[ny,~]=size(f);
v=ones(ny,1);
    if     periodic==0
        %2nd-order central difference
        A=1*spdiags(v,1,ny,ny)-1*spdiags(v,-1,ny,ny);
        A(1,1)=-3;A(1,2)=4;A(1,3)=-1; %First node forward
        A(ny,ny)=3;A(ny,ny-1)=-4;A(ny,ny-2)=1; %Last node backward
        A=A/(2*Dy);
        dfdy=A*f;
    elseif periodic==1
        %4th-order central difference
        ny=ny-1; %Eliminate repetitive entry 
        A=1*spdiags(v,-2,ny,ny)-8*spdiags(v,-1,ny,ny)+8*spdiags(v,1,ny,ny)-1*spdiags(v,2,ny,ny);
        A(1,ny-1)=1; A(1,ny)=-8; A(2,ny)=1;
        A(ny,1)=8;  A(ny,2)=-1;  A(ny-1,1)=-1;
        A=A/(12*Dy);
        dfdy=A*f(1:(end-1),:);
        dfdy=[dfdy;dfdy(1,:)];
    end

end       