
function Xk= ditfft(xn)
 
    M=nextpow2(length(xn));%M为指数

    N=2^M;%xn的长度为N

    for m=0:N/2-1%蝶形因子的指数范围

        WN(m+1)=exp(-j*2*pi/N)^m;%计算蝶形因子

    end
 
    A=[xn,zeros(1,N-length(xn))];%数据输入

    disp('输入到各存储单元的数据:');

    disp(A);

    %倒序

    J=0;%给倒序赋初始值
 
    for I=0:N-1%按序交换数据和算倒序数

        if I<J%条件判断及数据交换

            T=A(I+1);

            A(I+1)=A(J+1);

            A(J+1)=T;

        end

        K= N/2;

        while J>=K

        J=J-K;

        K= K/2;

        end

        J=J+K;

    end
 
    disp('倒序后各个存储单元的数据:');

    disp(A);
 
%
 
    for L=1:M

        disp('运算级次:');

        disp(L) ;

    B=2^(L- 1);
 
        for R=0:B- 1

        P=2^(M-L) * R;
 
            for K=R:2^L:N-2

            T=A(K+1)+A(K+B+1)* WN(P+1);

            A(K+B+1)=A(K+1)-A(K+B+1)*WN(P+1);

            A(K+1)=T;
 
            end
 
        end
 
    disp('本级运算后各存储单元的数据:');disp(A);
 
    end
 
    disp('输出各存储单元的数据:');
 
    Xk=A;
end 
 
