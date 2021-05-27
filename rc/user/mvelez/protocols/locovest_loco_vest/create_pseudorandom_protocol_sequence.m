% create a pseudo randomized sequence for the protocols

% restart random number generator
rng(1)

% para
n_loops             = 16;   % should be even
n_protocols         = 3;

prot.locovest       = 1;
prot.loco           = 2;
prot.vest           = 3;
prot.vest_from_bank = 4;


% create and randomize the order
order = repmat(1:prot.vest, n_loops/2, 2);
order(:, end) = prot.vest_from_bank;
for i = 1 : size(order, 1)
    idx = randperm(size(order, 2));
    order(i, :) = order(i, idx);
end



% make sure vest doesn't follow a nother vest
all_ok = false;
while ~all_ok
    
    all_ok = true;
    
    for i = 1 : size(order, 1)
        for j = 1 : size(order, 2)-1
            if order(i, j) == prot.vest_from_bank && order(i, j+1) == prot.vest
                order(i, j) = prot.vest;
                order(i, j+1) = prot.vest_from_bank;
                all_ok = false;
            end
        end
    end
end


% make sure sequence doesn't start with a vest following a protocol
for i = 1 : size(order, 1)
    if order(i, 1) == prot.vest
        idx = find(order(i, :) == prot.locovest | order(i, :) == prot.loco);
        idx(order(i, idx - 1) == prot.vest_from_bank) = [];
        idx2 = randi(length(idx), 1);
        order(i, 1) = order(i, idx(idx2));
        order(i, idx(idx2)) = prot.vest;
    end
end


% make sure the following vests follow equal # of loco and locovest
order = order';
order = order(:);
vest_idx = find(order == prot.vest);
preceding = order(vest_idx-1);

n_locovest = sum(preceding == prot.locovest);
n_loco = sum(preceding == prot.loco);

n_loco_to_swap = (n_loco - n_locovest)/2;

if n_loco_to_swap > 0
    idx = find(preceding == prot.loco);
    idx2 = randperm(length(idx), n_loco_to_swap);
    idx_to_swap = vest_idx(idx(idx2))-1;
    idx_to_swap2 = find(order == prot.locovest);
    idx_to_swap2(ismember(idx_to_swap2, vest_idx-1)) = [];
    idx2 = randperm(length(idx_to_swap2), n_loco_to_swap);
    order(idx_to_swap) = prot.loco;
    order(idx_to_swap2(idx2)) = prot.locovest;
elseif n_loco_to_swap < 0
    idx = find(preceding == prot.locovest);
    idx2 = randperm(length(idx), -n_loco_to_swap);
    idx_to_swap = vest_idx(idx(idx2))-1;
    idx_to_swap2 = find(order == prot.loco);
    idx_to_swap2(ismember(idx_to_swap2, vest_idx-1)) = [];
    idx2 = randperm(length(idx_to_swap2), -n_loco_to_swap);
    order(idx_to_swap) = prot.locovest;
    order(idx_to_swap2(idx2)) = prot.loco;
end

