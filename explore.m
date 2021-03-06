classdef explore
    
    methods (Static)
        
        function parexsol = explore2par(par_base, parnames, parvalues)
            % EXPLOREPAR is used to explore 2 different parameters using a parallel pool.
            % The code is likely to require modification for individual parameters
            % owing to possible dependencies.
            % PAR_BASE is the base parameter set
            % PARNAMES is a cell array with the parameter names in - check these
            % carefully to avoid heartache later
            % PARVALUES is matrix with the parameter value ranges e.g.
            
            tic
            disp('Starting parameter exploration');
            disp(['Parameter 1: ', parnames(1)]);
            disp(['Parameter 2: ', parnames(2)]);
            parval1 = cell2mat(parvalues(1));
            parval2 = cell2mat(parvalues(2));
            str1 = char(parnames(1));
            str2 = char(parnames(2));
            
            j = 1;
            
            parfor i = 1:length(parval1)
                
                par = par_base;
                par.Ana = 0;
                par = exploreparhelper(par, str1, parval1(i));
                par.taup(1) = par.taun(1);
                
                Voc_f = zeros(1, length(parval2));
                Voc_r = zeros(1, length(parval2));
                Jsc_f = zeros(1, length(parval2));
                Jsc_r = zeros(1, length(parval2));
                mpp_f = zeros(1, length(parval2));
                mpp_r = zeros(1, length(parval2));
                FF_f = zeros(1, length(parval2));
                FF_r = zeros(1, length(parval2));
                Voc_stable = zeros(1, length(parval2));
                PLint = zeros(1, length(parval2));
                
                for j = 1:length(parval2)
                    
                    runN = (i-1)*length(parval2) + j;
                    disp(['Run no. ', num2str(runN), ', taun = ', num2str(parval1(i)), ', E0 = ', num2str(parval2(j))]);
                    
                    par = exploreparhelper(par, str2, parval2(j));
                    
                    soleq = equilibrate(par);
                    % JV = doJV(soleq.i_sr, 50e-3, 100, 1, 1e-10, 0, 1.5, 2);
                    JV = doJV(soleq.eq_sr, 50e-3, 100, 1, 0, 0, 1.3, 2);
                    
                    Voc_f(j) = JV.stats.Voc_f;
                    Voc_r(j) = JV.stats.Voc_r;
                    Jsc_f(j) = JV.stats.Jsc_f;
                    Jsc_r(j) = JV.stats.Jsc_r;
                    mpp_f(j) = JV.stats.mpp_f;
                    mpp_r(j) = JV.stats.mpp_r;
                    FF_f(j) = JV.stats.FF_f;
                    FF_r(j) = JV.stats.FF_r;
                    
                    % For PL
                    %                     [sol_Voc, Voc] = findVoc(soleq.i_sr, 1e-6, Voc_f(j), (Voc_f(j)+0.1))
                    %                     Voc_stable(j) = Voc;
                    %                     PLint(j) = sol_Voc.PLint(end);
                    
                end
                
                A(i,:) = Voc_f;
                B(i,:) = Voc_r;
                C(i,:) = Jsc_f;
                D(i,:) = Jsc_r;
                E(i,:) = mpp_f;
                F(i,:) = mpp_r;
                G(i,:) = FF_f;
                H(i,:) = FF_r;
                %                 J(i,:) = Voc_stable;
                %                 K(i,:) = PLint;
                
            end
            
            parexsol.stats.Voc_f = A;
            parexsol.stats.Voc_r = B;
            parexsol.stats.Jsc_f = C;
            parexsol.stats.Jsc_r = D;
            parexsol.stats.mpp_f = E;
            parexsol.stats.mpp_r = F;
            parexsol.stats.FF_f = G;
            parexsol.stats.FF_r = H;
            %             parexsol.stats.Voc_stable = J;
            %             parexsol.stats.PLint = K;
            parexsol.parnames = parnames;
            parexsol.parvalues = parvalues;
            parexsol.parval1 = parval1;
            parexsol.parval2 = parval2;
            parexsol.par_base = par_base;
            
            toc
        end
        
        function par = exploreparhelper(par, parname, parvalue)
            % takes parameter set and sets parname to parvalue- workaround for parallel
            % computing loops
            eval(['par.',parname,'=parvalue']);
        end
        
        function plotPL(parexsol)
            
            figure(3000)
            s1 = surf(parexsol.parval1, parexsol.parval2, parexsol.stats.PLint);
            ylabel(parexsol.parnames(1))
            xlabel(parexsol.parnames(2))
            set(s1,'YScale','log');
            zlabel('PL intensity [cm-2s-1]')
            shading interp
            colorbar
            
        end
        
        function plotVoc(parexsol)
            
            offset = parexsol.parval2-parexsol.par_base.IP(1);
            
            figure(3001)
            surf(offset, parexsol.parval1, parexsol.stats.Voc_f)
            s1 = gca;
            %ylabel('Ion density [cm-3]')
            ylabel('p-type SRH time constant [s]')
            xlabel('\Phi_A')%/p-type VB-Fermi level offset [eV]')
            zlabel('Voc F scan [V]')
            xlim([offset(1), offset(end)]);
            ylim([parexsol.parval1(1), parexsol.parval1(end)])
            set(s1,'YScale','log');
            shading interp
            colorbar
            %caxis([0.75, 0.95])
            
            figure(3002)
            surf(offset, parexsol.parval1, parexsol.stats.Voc_r)
            s1 = gca;
            %ylabel('Ion density [cm-3]')
            ylabel('p-type SRH time constant [s]')
            xlabel('p-type VB-Fermi level offset [eV]')
            zlabel('Voc R scan [V]')
            xlim([offset(1), offset(end)]);
            ylim([parexsol.parval1(1), parexsol.parval1(end)])
            set(s1,'YScale','log');
            shading interp
            colorbar
            %caxis([0.75, 0.95])
            
        end
        
        function plotVocstable(parexsol)
            
            offset = parexsol.parval2-parexsol.par_base.IP(1);
            
            figure(3001)
            surf(offset, parexsol.parval1, parexsol.stats.Voc_stable)
            s1 = gca;
            ylabel('Mobile ion density [cm-3]')
            %ylabel('p-type SRH time constant [s]')
            xlabel('p-type VB-Fermi level offset [eV]')
            zlabel('Voc F scan [V]')
            xlim([offset(1), offset(end)]);
            ylim([parexsol.parval1(1), parexsol.parval1(end)])
            set(s1,'YScale','log');
            shading interp
            colorbar
            caxis([0.75, 0.95])
            %caxis([1.05, 1.15])
        end
        
        
        function plotJscF(parexsol)
            
            offset = parexsol.parval2-parexsol.par_base.IP(1);
            
            figure(3001)
            surf(offset, parexsol.parval1, parexsol.stats.Jsc_f)
            s1 = gca;
            %ylabel('Mobile ion density [cm-3]')
            ylabel('p-type SRH time constant [s]')
            xlabel('p-type VB-Fermi level offset [eV]')
            zlabel('Jsc F scan [Acm-2]')
            xlim([offset(1), offset(end)]);
            ylim([parexsol.parval1(1), parexsol.parval1(end)])
            set(s1,'YScale','log');
            shading interp
            colorbar
            %caxis([0.75, 0.95])
            %caxis([1.05, 1.15])
        end
        
        
    end
    
end
