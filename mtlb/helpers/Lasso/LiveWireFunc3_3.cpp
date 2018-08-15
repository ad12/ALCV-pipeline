/*==========================================================
 * LiveWireFunc3_3.cpp
 *
 * Computes a live wire gradient search for a source pixel 
 * to all pixels in an image
 *
 * The calling syntax is:
 *
 *		p = LiveWireFunc2(neiList,d,imSize(1),row,col); 
 *
 *  neiList   - neighborhood list of each pixel made in MATLAB
 *  d         - cost vector
 *  imSize(1) - number of rows in image
 *  row, col  - coordiates of the source pixel
 *
 * Copyright @2016 Dibyendu Mukherjee
 *
 *========================================================*/

#include <stdlib.h>
#include "mex.h"

typedef struct treeNode
{
	double data;
	int idx;
	struct treeNode *left;
	struct treeNode *right;

}treeNode;

treeNode* FindMin(treeNode *node)
{
	if(node==NULL)
	{
		/* There is no element in the tree */
		return NULL;
	}
	if(node->left) /* Go to the left sub tree to find the min element */
		return FindMin(node->left);
	else 
		return node;
}

treeNode* FindMinAndDelete(treeNode *node, double *data, int *idx)
{
	treeNode *temp = NULL;
	if(node==NULL)
	{
		*data = -1;
		*idx = -1;
		return NULL;
	}
	if (node->left)
		node->left = FindMinAndDelete(node->left, data, idx);
	else{
		*data = node->data;
		*idx = node->idx;
		temp = node;
		node = node->right;
		free(temp);
	}
	return node;
}

treeNode* FindMax(treeNode *node)
{
	if(node==NULL)
	{
		/* There is no element in the tree */
		return NULL;
	}
	if(node->right) /* Go to the left sub tree to find the min element */
		FindMax(node->right);
	else 
		return node;
}

treeNode * Insert(treeNode *node,double data, int idx)
{
	if(node==NULL)
	{
		treeNode *temp;
		temp = (treeNode *)malloc(sizeof(treeNode));
		temp -> data = data;
		temp -> idx = idx;
		temp -> left = temp -> right = NULL;
		return temp;
	}

	if(data >(node->data))
	{
		node->right = Insert(node->right,data,idx);
	}
	else if(data < (node->data))
	{
		node->left = Insert(node->left,data,idx);
	}
	else{
		if(idx >(node->idx))
		{
			node->right = Insert(node->right,data,idx);
		}
		else if(idx < (node->idx))
		{
			node->left = Insert(node->left,data,idx);
		}
	}
	/* Else there is nothing to do as the data is already in the tree. */
	return node;

}

treeNode * Delete(treeNode *node, double data, int idx)
{
	treeNode *temp;
	if(node==NULL)
	{
		printf("Element Not Found");
	}
	else if(data < node->data)
	{
		node->left = Delete(node->left, data, idx);
	}
	else if(data > node->data)
	{
		node->right = Delete(node->right, data, idx);
	}
	else
	{
		if(idx < node->idx)
		{
			node->left = Delete(node->left, data, idx);
		}
		else if(idx > node->idx)
		{
			node->right = Delete(node->right, data, idx);
		}
		else{

			/* Now We can delete this node and replace with either minimum element 
			in the right sub tree or maximum element in the left subtree */
			if(node->right && node->left)
			{
				/* Here we will replace with minimum element in the right sub tree */
				temp = FindMin(node->right);
				node -> data = temp->data; 
				node -> idx = temp->idx; 
				/* As we replaced it with some other node, we have to delete that node */
				node -> right = Delete(node->right,temp->data,temp->idx);
			}
			else
			{
				/* If there is only one or zero children then we can directly 
				remove it from the tree and connect its parent to its child */
				temp = node;
				if(node->left == NULL)
					node = node->right;
				else if(node->right == NULL)
					node = node->left;
				free(temp); /* temp is longer required */ 
			}
		}
	}
	return node;

}

treeNode * Find(treeNode *node, double data, int idx)
{
	if(node==NULL)
	{
		/* Element is not found */
		return NULL;
	}
	if(data > node->data)
	{
		/* Search in the right sub tree. */
		return Find(node->right,data,idx);
	}
	else if(data < node->data)
	{
		/* Search in the left sub tree. */
		return Find(node->left,data,idx);
	}
	else
	{
		if(idx > node->idx)
		{
			/* Search in the right sub tree. */
			return Find(node->right,data,idx);
		}
		else if(idx < node->idx)
		{
			/* Search in the left sub tree. */
			return Find(node->left,data,idx);
		}
		else
		{
			/* Element Found */
			return node;
		}
	}
}

void PrintInorder(treeNode *node)
{
	if(node==NULL)
	{
		return;
	}
	PrintInorder(node->left);
	printf("(%f, %d) ",node->data,node->idx);
	PrintInorder(node->right);
}

void PrintPreorder(treeNode *node)
{
	if(node==NULL)
	{
		return;
	}
	printf("(%f, %d) ",node->data,node->idx);
	PrintPreorder(node->left);
	PrintPreorder(node->right);
}

void PrintPostorder(treeNode *node)
{
	if(node==NULL)
	{
		return;
	}
	PrintPostorder(node->left);
	PrintPostorder(node->right);
	printf("(%f, %d) ",node->data,node->idx);
}

/* The computational routine */
void liveWire(double *neiList, int sourcePt, double *d, double *p, int dataSize, int nrows, int rad)
{
    int i, j = 1, lenL = 1, row, col, ncols = dataSize/nrows;
    int sourcePtX, sourcePtY, destPtX, destPtY;
	double minCost, gTmp, *g, radSq = ((double)(rad))*((double)rad), distVal = 0;
	int q, r, *tmp;
	bool *e, *L;
        
    //sourcePt = sourcePtX*nrows + sourcePtY;
    sourcePtX = (int)(sourcePt/nrows);
    sourcePtY = sourcePt%nrows;
    treeNode *root = NULL, *temp = NULL;
	g = (double*) calloc(dataSize,sizeof(double));
	L = (bool*) calloc(dataSize, sizeof(bool));
	e = (bool*) calloc(dataSize, sizeof(bool)); // Keep track of elements that are expanded
    root = Insert(root, 0,sourcePt);
	L[sourcePt] = true;
    
	while(lenL>0)
	{
        root = FindMinAndDelete(root,&minCost,&q);
        if (q==-1)
        {
            break;
        }       
        
		e[q] = true;
		L[q] = false;
		lenL = lenL - 1;
        
        if (rad>0){
            destPtX = (int)(q/nrows);
            destPtY = q%nrows;
            distVal = ((destPtX-sourcePtX)*(destPtX-sourcePtX))+((destPtY-sourcePtY)*(destPtY-sourcePtY));
        }
        if (distVal>radSq)
        {
            continue;
        }

		for (i=0; i<8; i++){
            r = neiList[i*dataSize+q]-1;
            if ((r>=0) && (!e[(int)r]))
            {
                if (rad>0){
                    destPtX = (int)(r/nrows);
                    destPtY = r%nrows;
                    distVal = ((destPtX-sourcePtX)*(destPtX-sourcePtX))+((destPtY-sourcePtY)*(destPtY-sourcePtY));
                }
                if (distVal>radSq)
                {
                    continue;
                }
                
                gTmp = g[q] + d[i*dataSize+q];
                if (L[r] && (gTmp<g[r]))
                {
                    L[r] = false;
                    lenL = lenL - 1;
                    root = Delete(root,g[r],r);
                }
                if (!L[r])
                {
                    g[r] = gTmp;
                    p[r] = (double)(q+1); // Matlab indexing
                    
                    L[r] = true;
                    lenL = lenL + 1;
                    root = Insert(root, g[r],r);
                }

            }
        }
	}
}

/* The gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
    int sourcePt, row, col, rad;              /* input scalar */
    double *neiList, *d;               /* input matrices */
    size_t dataSize, nrows;                   /* size of matrix */
    double *p;              /* output vector */

    /* check for proper number of arguments */
    if((nrhs<5) || (nrhs>6)) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs","Five or six inputs required.");
    }
    if(nlhs!=1) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nlhs","One output required.");
    }
    /* make sure the first input argument is scalar */
    /*if( !mxIsDouble(prhs[0]) || 
         mxIsComplex(prhs[0]) ||
         mxGetNumberOfElements(prhs[0])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notScalar","Input multiplier must be a scalar.");
    }*/
    
    /* make sure the second input argument is type double */
    /*if( !mxIsDouble(prhs[1]) || 
         mxIsComplex(prhs[1])) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notDouble","Input matrix must be type double.");
    }*/
    
    /* check that number of rows in second input argument is 1 */
    /*if(mxGetM(prhs[1])!=1) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notRowVector","Input must be a row vector.");
    }*/
    
    /* get the pointer to the neighbour list */
    neiList = mxGetPr(prhs[0]);
    
	/* create a pointer to the cost vector */
    d = mxGetPr(prhs[1]);
    
    /* get the value of number of rows */
    nrows = mxGetScalar(prhs[2]);

    /* create a value of the source point */
    row = mxGetScalar(prhs[3]);
    col = mxGetScalar(prhs[4]);
    
    if (nrhs==6)
    {
        rad = mxGetScalar(prhs[5]); // radius of computation (for large images)
    }else{
        rad = 0;
    }
            
    /* get dimensions of the input matrix */
	dataSize = mxGetM(prhs[0]);
    
    sourcePt = (col*nrows)+row;

    /* create the output vector */
    plhs[0] = mxCreateDoubleMatrix((mwSize)dataSize,1,mxREAL);

    /* get a pointer to the real data in the output matrix */
    p = mxGetPr(plhs[0]);

    /* call the computational routine */
    //arrayProduct(multiplier,inMatrix,outMatrix,(mwSize)ncols);
	liveWire(neiList, sourcePt, d, p, dataSize, nrows, rad);
}
