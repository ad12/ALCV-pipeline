function [lens_score] = calculate_lens_score(I, niqe_params)
I = imresize(I,[224, 224]);
[Qg1,Qch1]=blindimagequality(I);
                    
I = uint8(I);
niqe_score = computequality(I,niqe_params.blocksizerow, niqe_params.blocksizecol, niqe_params.blockrowoverlap, niqe_params.blockcoloverlap, ...
                            niqe_params.mu_prisparam, niqe_params.cov_prisparam);          
                    
tmp1 = Qg1*10000;
tmp2 = 1000-niqe_score;

lens_score = tmp1+tmp2;

end
