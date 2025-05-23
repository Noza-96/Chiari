function dfdx=dfdx1(f,x,periodic)
        Dx=x(1,2)-x(1,1);
        [~,nx]=size(f); 
        v=ones(nx,1);
    if periodic==0
        %2nd-order central difference
        A=1*spdiags(v,1,nx,nx)-1*spdiags(v,-1,nx,nx);
        A(1,1)=-3;A(1,2)=4;A(1,3)=-1; %First node forward
        A(nx,nx)=3;A(nx,nx-1)=-4;A(nx,nx-2)=1; %Last node backward
        A=A/(2*Dx);      
        dfdx=f*transpose(A);
    elseif periodic==1
        %4th-order central difference
        nx=nx-1;
        A=-1*spdiags(v,2,nx,nx)+8*spdiags(v,1,nx,nx)-8*spdiags(v,-1,nx,nx)+1*spdiags(v,-2,nx,nx);
        A(1,nx)=-8; A(1,nx-1)=1; A(2,nx)=1;
        A(nx,1)=8;  A(nx,2)=-1; A(nx-1,1)=-1;
        A=A/(12*Dx);
        dfdx=f(:,1:(end-1))*transpose(A);
        dfdx=[dfdx,dfdx(:,1)];
    end  
    
end