#include <bits/stdc++.h>
#include <cuda_runtime.h>
#include <chrono>
#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#include <thrust/transform.h>
#include <thrust/sort.h>
#include <fstream>
using namespace std;
typedef long long ll;
typedef unsigned long long ull;
#define pb push_back

const int bucketSize = 500; // size of the bucket

// Create 2 classes, one for node and one for tree;

class node {
public:
    bool isLeaf;
    node** ptr;
    int *key, size;
    node();
};
node::node()
{
    key = new int[bucketSize];
    ptr = new node*[bucketSize + 1]();
}
class Btree {
public:
    // Root of tree stored here;
    node* root;
    Btree();
    void deleteNode(int);

    int search(int);
    void display(node*);
    void insert(int);
    node* findParent(node*, node*);
    node* getRoot();
    void shiftLevel(int, node*, node*);
    void genLevelArray(node*);
    void createLevelArray(node*);
};

node* Btree::getRoot() { return root; }
Btree::Btree() { root = NULL; }

void Btree::insert(int x)
{
    if (root == NULL) {
        root = new node;
        root->key[0] = x;
        root->isLeaf = true;
        root->size = 1;
    }

    else {
        node* current = root;
        node* parent;

        while (current->isLeaf == false) {
            parent = current;

            for (int i = 0; i < current->size; i++) {
                if (x < current->key[i]) {
                    current = current->ptr[i];
                    break;
                }

                if (i == current->size - 1) {
                    current = current->ptr[i + 1];
                    break;
                }
            }
        }

        // now we have reached leaf;
        if (current->size < bucketSize) { // if the node to be inserted is
                                         // not filled
            int i = 0;

            // Traverse btree
            while (x > current->key[i] && i < current->size)
                // goto pt where needs to be inserted.
                i++;
            for (int j = current->size; j > i; j--)
                // adjust and insert element;
                current->key[j] = current->key[j - 1];

            current->key[i] = x;

            // size should be increased by 1
            current->size++;

            current->ptr[current->size] = current->ptr[current->size - 1];
            current->ptr[current->size - 1] = NULL;
        }

        // if block does not have enough space;
        else {
            node* newLeaf = new node;
            int tempNode[bucketSize + 1];

            for (int i = 0; i < bucketSize; i++)
                // all elements of this block stored
                tempNode[i] = current->key[i];
            int i = 0;

            // find the right posn of num to be inserted
            while (x > tempNode[i] && i < bucketSize)
                i++;

            for (int j = bucketSize + 1; j > i; j--)
                tempNode[j] = tempNode[j - 1];
            tempNode[i] = x;
            // inserted element in its rightful position;

            newLeaf->isLeaf = true;
            current->size = (bucketSize + 0) / 2;
            newLeaf->size = (bucketSize + 1) - (bucketSize + 1) / 2  ; // now rearrangement begins!

            current->ptr[current->size] = newLeaf;
            newLeaf->ptr[newLeaf->size] = current->ptr[bucketSize];

            current->ptr[newLeaf->size] = current->ptr[bucketSize];
            current->ptr[bucketSize] = NULL;

            for (int i = 0; i < current->size; i++)
                current->key[i] = tempNode[i];

            for (int i = 0, j = current->size;
                 i < newLeaf->size; i++, j++)
                newLeaf->key[i] = tempNode[j];

            // if this is root, then fine,
            // else we neeThank you for your time and attention.d to increase the height of tree;
            if (current == root) {
                node* newRoot = new node;
                newRoot->key[0] = newLeaf->key[0];
                newRoot->ptr[0] = current;
                newRoot->ptr[1] = newLeaf;
                newRoot->isLeaf = false;
                newRoot->size = 1;
                root = newRoot;
            }
            else
                shiftLevel(
                    newLeaf->key[0], parent,
                    newLeaf); // parent->original root
        }
    }
}

void Btree::shiftLevel(int x, node* current, node* child)
{ // insert or create an internal node;
    if (current->size
        < bucketSize) { // if can fit in this level, do that
        int i = 0;
        while (x > current->key[i] && i < current->size)
            i++;
        for (int j = current->size; j > i; j--)
            current->key[j] = current->key[j - 1];

        for (int j = current->size + 1; j > i + 1; j--)
            current->ptr[j] = current->ptr[j - 1];

        current->key[i] = x;
        current->size++;
        current->ptr[i + 1] = child;
    }

    // shift up
    else {
        node* newInternal = new node;
        int tempKey[bucketSize + 1];
        node* tempPtr[bucketSize + 2];

        for (int i = 0; i < bucketSize; i++)
            tempKey[i] = current->key[i];

        for (int i = 0; i < bucketSize + 1; i++)
            tempPtr[i] = current->ptr[i];

        int i = 0;
        while (x > tempKey[i] && i < bucketSize)
            i++;

        for (int j = bucketSize + 1; j > i; j--)
            tempKey[j] = tempKey[j - 1];

        tempKey[i] = x;
        for (int j = bucketSize + 2; j > i + 1; j--)
            tempPtr[j] = tempPtr[j - 1];

        tempPtr[i + 1] = child;
        newInternal->isLeaf = false;
        current->size = (bucketSize + 1) / 2;

        newInternal->size
            = bucketSize - (bucketSize + 1) / 2;

        for (int i = 0, j = current->size + 1;
             i < newInternal->size; i++, j++)
            newInternal->key[i] = tempKey[j];

        for (int i = 0, j = current->size + 1;
             i < newInternal->size + 1; i++, j++)
            newInternal->ptr[i] = tempPtr[j];

        if (current == root) {
            node* newRoot = new node;
            newRoot->key[0] = current->key[current->size];
            newRoot->ptr[0] = current;
            newRoot->ptr[1] = newInternal;
            newRoot->isLeaf = false;
            newRoot->size = 1;
            root = newRoot;
        }

        else
            shiftLevel(current->key[current->size],
                       findParent(root, current),
                       newInternal);
    }
}
int Btree::search(int x)
{
    if (root == NULL)
        return -1;

    else {
        node* current = root;
        while (current->isLeaf == false) {
            for (int i = 0; i < current->size; i++) {
                if (x < current->key[i]) {
                    current = current->ptr[i];
                    break;
                }

                if (i == current->size - 1) {
                    current = current->ptr[i + 1];
                    break;
                }
            }
        }

        for (int i = 0; i < current->size; i++) {
            if (current->key[i] == x) {
                // cout<<"Key found "<<endl;
                return 1;
                // return;
            }
        }

        // cout<<"Key not found"<<endl;
        return 0;
    }
}

// Print the tree
void Btree::display(node* current)
{
    if (current == NULL)
        return;
    queue<node*> q;
    q.push(current);
   
    while (!q.empty()) {
        int l;
        l = q.size();

        for (int i = 0; i < l; i++) {
            node* tNode = q.front();
            q.pop();
            
            for (int j = 0; j < tNode->size; j++)
                if (tNode != NULL)  cout << tNode->key[j] <<" ";
           
            for (int j = 0; j < tNode->size + 1; j++)
                if (tNode->ptr[j] != NULL && tNode->isLeaf == false) q.push(tNode->ptr[j]); 

            cout << "\t";
        }
        cout << endl;
    }
}

node* Btree::findParent(node* current, node* child)
{
    node* parent;
    if (current->isLeaf || (current->ptr[0])->isLeaf)
        return NULL;

    for (int i = 0; i < current->size + 1; i++) {
        if (current->ptr[i] == child) {
            parent = current;
            return parent;
        }
        else {
            parent = findParent(current->ptr[i], child);
            if (parent != NULL)
                return parent;
        }
    }
    return parent;
}

vector<int> level_1_keys;
vector<int> lev1_child_end_idx;
vector<int> level_2_keys;
vector<int> lev2_child_end_idx;
vector<int> level_3_keys;
vector<int> lev3_child_end_idx;
vector<int> level_f_keys;


void Btree::createLevelArray(node* current)
{   
    int ht_tree = 1;
    queue<node*> q;
    q.push(current);
    while (!q.empty()) {
        if(ht_tree == 1) { 
            level_1_keys.clear();
            lev1_child_end_idx.clear();}
        if(ht_tree == 2) { 
            level_2_keys.clear();
            lev2_child_end_idx.clear(); }
        if(ht_tree == 3) { 
            level_3_keys.clear();
            lev3_child_end_idx.clear(); }
        if(ht_tree == 4 || ht_tree == 3) { level_f_keys.clear();  }

        int l;
        l = q.size();
        cout<<"q size is "<<l<<endl;
        int ch_idx = -1;
        for (int i = 0; i < l; i++) {
            node* tNode = q.front();
            q.pop();
            if(ht_tree == 1) level_1_keys.pb(-1);
            if(ht_tree == 2) level_2_keys.pb(-1);
            if(ht_tree == 3) level_3_keys.pb(-1);   
            if(tNode->isLeaf == true) level_f_keys.pb(-1);

            for (int j = 0; j < tNode->size; j++){
                if(ht_tree == 1) level_1_keys.pb(tNode->key[j]);
                if(ht_tree == 2) level_2_keys.pb(tNode->key[j]);
                if(ht_tree == 3) level_3_keys.pb(tNode->key[j]);   
                if(tNode->isLeaf == true) level_f_keys.pb(tNode->key[j]); 
                }

            if(ht_tree == 1 )cout<<"lev1 size "<<level_1_keys.size()<<" tNode size  "<<tNode->size<<endl;
            for (int j = 0; j < tNode->size + 1; j++) {                    
                if(tNode->ptr[j] != NULL )ch_idx += tNode->ptr[j]->size+1;
                if(ht_tree == 1 )lev1_child_end_idx.pb(ch_idx);
                if(ht_tree == 2 )lev2_child_end_idx.pb(ch_idx);
                if(ht_tree == 3 )lev3_child_end_idx.pb(ch_idx);
                if (tNode->ptr[j] != NULL && tNode->isLeaf == false) q.push(tNode->ptr[j]); }
        }
        ht_tree++;
    }
  
}


void saveArray(const std::string &filename, int arr[], int size) {
    std::ofstream outFile(filename, std::ios::binary);
    if (!outFile) {
        std::cerr << "Error opening file for writing\n";
        return;
    }
    outFile.write(reinterpret_cast<char*>(&size), sizeof(size));  // Save size
    outFile.write(reinterpret_cast<char*>(arr), size * sizeof(int));  // Save array
    outFile.close();
}

void loadArray(const std::string &filename, int *&arr, int &size) {
    std::ifstream inFile(filename, std::ios::binary);
    if (!inFile) {
        std::cerr << "Error opening file for reading\n";
        return;
    }
    // cout<<"file opened  file name  "<<filename<<endl;
    inFile.read(reinterpret_cast<char*>(&size), sizeof(size));  
    arr = (int*)malloc(size * sizeof(int)); 
    inFile.read(reinterpret_cast<char*>(arr), size * sizeof(int)); 
    inFile.close();
}



void storeDataDevice(string str){

    cudaEvent_t startc, stopc;
    cudaEventCreate(&startc);
    cudaEventCreate(&stopc);
    auto start = std::chrono::high_resolution_clock::now();
    cudaEventRecord(startc, 0);

    int l1sz, l2sz, l3sz, lfsz;
    int* h_l1keys;
    int* h_l2keys;
    int* h_l3keys;
    int* h_lfkeys;
    int* h_l1chid;
    int* h_l2chid;
    int* h_l3chid;

    loadArray("abbig_data_files/lev1_keys_"+str+".dat", h_l1keys, l1sz);
    loadArray("abbig_data_files/lev2_keys_"+str+".dat", h_l2keys, l2sz);
    loadArray("abbig_data_files/lev3_keys_"+str+".dat", h_l3keys, l3sz);
    loadArray("abbig_data_files/leaf_keys_"+str+".dat", h_lfkeys, lfsz);
    loadArray("abbig_data_files/lev1_indx_"+str+".dat", h_l1chid, l1sz);
    loadArray("abbig_data_files/lev2_indx_"+str+".dat", h_l2chid, l2sz);
    loadArray("abbig_data_files/lev3_indx_"+str+".dat", h_l3chid, l3sz);
    cout<<"l1sz "<<l1sz<<" , l2sz "<<l2sz<<"  l3sz "<<l3sz<<"  lfsz "<<lfsz<<endl;

    int tot_size = (2*(l1sz + l2sz + l3sz) + lfsz )*sizeof(int);
    cout<<"total size "<<tot_size/(1024*1024)<<"MB"<<endl;



    int* d_l1keys;
    int* d_l2keys;
    int* d_l3keys;
    int* d_lfkeys;
    int* d_l1chid;
    int* d_l2chid;
    int* d_l3chid;

    cudaMalloc((void**)&d_l1keys, l1sz*sizeof(int));
    cudaMalloc((void**)&d_l2keys, l2sz*sizeof(int));
    cudaMalloc((void**)&d_l3keys, l3sz*sizeof(int));
    cudaMalloc((void**)&d_lfkeys, lfsz*sizeof(int));
    cudaMalloc((void**)&d_l1chid, l1sz*sizeof(int));
    cudaMalloc((void**)&d_l2chid, l2sz*sizeof(int));
    cudaMalloc((void**)&d_l3chid, l3sz*sizeof(int));

    cudaMemcpy(d_l1keys, h_l1keys, l1sz*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_l2keys, h_l2keys, l2sz*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_l3keys, h_l3keys, l3sz*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_lfkeys, h_lfkeys, lfsz*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_l1chid, h_l1chid, l1sz*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_l2chid, h_l2chid, l2sz*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_l3chid, h_l3chid, l3sz*sizeof(int), cudaMemcpyHostToDevice);


    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<float, std::milli> duration = end - start;
    std::cout << "reading and copy time chron: " << duration.count() << " miliseconds" << std::endl;
    cudaEventRecord(stopc);
    cudaEventSynchronize(stopc);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, startc, stopc);
    std::cout << "reading and copy time cuda : " << milliseconds << " ms" << std::endl;   
    

    cudaFree(d_l1keys);
    cudaFree(d_l2keys);
    cudaFree(d_l3keys);
    cudaFree(d_l1chid);
    cudaFree(d_l2chid); 
    cudaFree(d_l3chid);


    delete[] h_l1keys;
    delete[] h_l2keys;
    delete[] h_l3keys;
    delete[] h_l1chid;
    delete[] h_l2chid;
    delete[] h_l3chid;

    level_1_keys.resize(0);
    level_2_keys.resize(0);
    level_3_keys.resize(0);
    level_f_keys.resize(0);
    lev1_child_end_idx.resize(0);
    lev2_child_end_idx.resize(0);
    lev3_child_end_idx.resize(0);


    return ;

}

int main()
{
    ios_base::sync_with_stdio(false);
    string str[12] = { "5mil","10mil", "5cr", "10cr","15cr", "20cr", "25cr", "30cr","50cr", "100cr","150cr", "200cr"};  
    // cout<<"str_lev_ser_32"<<endl;              //size  250 1mil 1cr 5cr 10cr 50cr
    int num_keys[12] = { 5000000, 10000000, 50000000, 100000000,150000000,200000000,250000000,300000000, 500000000, 1000000000, 1500000000,2000000000 };                //strn  2hn 1mil 1cr 5cr 10cr 50cr
    int idx =8;
    for(int i = idx; i<idx+1; i++){
        cout<<" ster serch "<<str[i]<<endl;
        // makeIndexLevels(num_keys[i], str[i]);
      
        // for(int j = 0 ; j<3; j++){
            storeDataDevice(str[i]);// }
    }
    return 0;
}
