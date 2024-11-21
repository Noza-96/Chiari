function dfdx=dfdx2(f,x,periodic)
        Dx=x(1,2)-x(1,1);
        [~,nx]=size(f);   
        v=ones(nx,1);
        if periodic==0
        %2nd-order central difference
        A=1*spdiags(v,-1,nx,nx)-2*spdiags(v,0,nx,nx)+1*spdiags(v,1,nx,nx);
        %2nd-order forward difference
        A(1,1:4)=[2, -5, 4, -1];
        %2nd-order backward difference
        A(nx,nx-3:nx)=fliplr(A(1,1:4));
        A=A/(Dx^2);
        dfdx=f*transpose(A);

    elseif periodic==1
        %4th-order central difference
        nx=nx-1;
        A=-1*spdiags(v,-2,nx,nx)+16*spdiags(v,-1,nx,nx)-30*spdiags(v,0,nx,nx)+16*spdiags(v,1,nx,nx)-1*spdiags(v,2,nx,nx);
        A(1,nx-1)=-1; A(1,nx)=16; 
        A(2,nx)=-1;
        A(nx,1)=16;  A(nx,2)=-1;  
        A(nx-1,1)=-1;
        A=A/(12*Dx^2);
        dfdx=f(:,1:(end-1))*transpose(A);
        dfdx=[dfdx,dfdx(:,1)];
    end
end