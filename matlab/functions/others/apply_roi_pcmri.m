function pcmri = apply_roi_pcmri(pcmri)
    for k = 1:pcmri.Ndat
        pcmri.x{k}=pcmri.x{k}(pcmri.roi{k});
        pcmri.y{k}=pcmri.y{k}(pcmri.roi{k});
        pcmri.z{k}=pcmri.z{k}(pcmri.roi{k});
        pcmri.u_normal{k}=pcmri.u_normal{k}(pcmri.roi{k},:);
    end
end